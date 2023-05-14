import 'dart:async';
import 'dart:io';

import 'package:dsbuild/reader/csv_reader.dart';
import 'package:dsbuild/transformer/postprocessor.dart';
import 'package:dsbuild/writer/dsbuild_writer.dart';
import 'package:logging/logging.dart';

import 'config.dart';
import 'model/conversation.dart';
import 'model/descriptor.dart';
import 'reader/fastchat_reader.dart';
import 'reader/reader.dart';
import 'registry.dart';
import 'repository.dart';
import 'transformer/preprocessor.dart';
import 'transformer/transformers.dart' as t;
import 'writer/fastchat_writer.dart';
import 'writer/writer.dart';

class DsBuild {
  final Config config;
  final Repository repository;
  final Registry registry;

  static Logger log = Logger("dsbuild");

  static final Map<String, Preprocessor Function(Map)> builtinPreprocessors = {
    'HtmlStrip': (config) => t.HtmlStrip(config),
    'Trim': (config) => t.Trim(config),
    'RegexReplace': (config) => t.RegexReplace(config),
    'ExactReplace': (config) => t.ExactReplace(config),
    'FullMatch': (config) => t.FullMatch(config),
    'RegexExtract': (config) => t.RegexExtract(config),
    'Encoding': (config) => t.EncodingPre(config),
  };

  static final Map<String, Postprocessor Function(Map)> builtinPostprocessors =
      {
    'Participants': (config) => t.Participants(config),
    'RenameParticipants': (config) => t.RenameParticipants(config),
    'Encoding': (config) => t.EncodingPost(config),
    'Trim': (config) => t.TrimPost(config),
  };

  static final Map<String, Reader Function(Map)> builtinReaders = {
    'csv': (config) => CsvReader(config),
    'fastchat': (config) => FastChatReader(config),
  };

  static final Map<String, Writer Function(Map)> builtinWriters = {
    'fastchat': (config) => FastChatWriter(config),
    'dsbuild': (config) => DsBuildWriter(config),
  };

  DsBuild(DatasetDescriptor descriptor,
      {Registry? registry, this.config = const Config()})
      : repository = Repository(descriptor),
        registry = registry ??
            Registry(builtinReaders, builtinWriters,
                preprocessors: builtinPreprocessors,
                postprocessors: builtinPostprocessors);

  /// Verify the descriptor is valid and all required transformers are registered.
  List<String> verifyDescriptor() {
    List<String> errors = [];

    // Verify preprocessors
    for (StepDescriptor step in repository.descriptor.preprocessorSteps) {
      if (!registry.preprocessors.containsKey(step.type)) {
        errors.add("No preprocessor matching type '${step.type}'");
      }
    }

    // Verify readers
    for (InputDescriptor input in repository.descriptor.inputs) {
      if (!registry.readers.containsKey(input.reader.type)) {
        errors.add("No reader matching type '${input.reader.type}'");
      }
    }

    // Verify postprocessors
    for (OutputDescriptor output in repository.descriptor.outputs) {
      for (StepDescriptor step in output.steps) {
        if (!registry.postprocessors.containsKey(step.type)) {
          errors.add("No postprocessor matching type '${step.type}'");
        }
      }
    }

    // Verify writers
    for (OutputDescriptor output in repository.descriptor.outputs) {
      if (!registry.writers.containsKey(output.writer.type)) {
        errors.add("No writer matching type '${output.writer.type}'");
      }
    }

    return errors;
  }

  /// Fetch all requirements.
  /// yields an InputDescriptor for each newly satisfied dependency.
  Stream<InputDescriptor> fetchRequirements() async* {
    HttpClient client = HttpClient();
    for (int i = 0; i < repository.descriptor.inputs.length; i++) {
      InputDescriptor input = repository.descriptor.inputs[i];
      if (input.source == null) {
        log.info("Skipping retrieval for ${input.path} (No source uri)");
        continue;
      }
      if (await File(input.path).exists()) {
        log.fine("Skipping fetch for existing input file '${input.path}'");
      } else {
        if (!['http', 'https'].contains(input.source!.scheme)) {
          log.severe("Unhandled URI input: '${input.source}'");
          continue;
        }
        log.info("Retrieving ${input.source}");
        final request = await client.getUrl(input.source!);
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          log.warning(
              "Failed to retrieve input data. Received http status ${response.statusCode}");
          await response.drain();
        } else {
          File file = await File(input.path).create(recursive: true);
          await response.pipe(file.openWrite());
        }
        yield input;
      }
    }
    client.close();
  }

  /// Perform the specified transformation steps.
  Stream<MessageEnvelope> transform(
      Stream<MessageEnvelope> messages, List<StepDescriptor> steps) {
    Stream<MessageEnvelope> pipeline = messages;
    for (StepDescriptor step in steps) {
      pipeline = pipeline.transform(
          registry.preprocessors[step.type]!.call(step.config).transformer);
    }
    return pipeline;
  }

  /// Perform the postprocessing steps defined in the OutputDescriptor
  Stream<Conversation> postProcess(
      Stream<Conversation> conversations, OutputDescriptor output) {
    Stream<Conversation> pipeline = conversations;
    for (StepDescriptor step in output.steps) {
      pipeline = pipeline.transform(
          registry.postprocessors[step.type]!.call(step.config).transformer);
    }
    return pipeline;
  }

  /// Utility function to concatenate multiple MessageEnvelope streams.
  Stream<Conversation> concatenateMessages(
      List<Stream<MessageEnvelope>> data) async* {
    for (Stream<MessageEnvelope> messageStream in data) {
      List<Message> convoMessages = [];
      String convoId = '';
      StreamTransformer<MessageEnvelope, Conversation>
          concatenatingTransformer =
          StreamTransformer.fromHandlers(handleData: (data, sink) {
        if (data.conversationId != convoId) {
          if (convoMessages.isNotEmpty) {
            Conversation conversation = Conversation(convoId.hashCode,
                messages: convoMessages, meta: {'inputId': convoId});
            sink.add(conversation);
            convoMessages = [];
          }
          convoId = data.conversationId;
          convoMessages.add(Message(data.from, data.value));
        } else {
          convoMessages.add(Message(data.from, data.value));
        }
      });
      yield* messageStream.transform(concatenatingTransformer);
    }
  }

  /// Transform each input according to it's InputDescriptor.
  /// The transformation output is concatenated, in the order of input, into a single Conversation stream
  /// The stream
  Stream<Conversation> transformAll() async* {
    List<Stream<MessageEnvelope>> pending = [];
    for (InputDescriptor inputDescriptor in repository.descriptor.inputs) {
      Stream<MessageEnvelope> pipeline =
          transform(read(inputDescriptor), inputDescriptor.steps);
      pending.add(pipeline);
    }
    yield* concatenateMessages(pending);
  }

  /// Write the output conversation stream to the specified output.
  /// Stream elements are unaltered.
  Stream<Conversation> write(
          Stream<Conversation> conversations, OutputDescriptor output) =>
      registry.writers[output.writer.type]!
          .call(output.writer.config)
          .write(conversations, output.path);

  /// Read the input specified by the InputDescriptor.
  /// yields MessageEnvelope for each message.
  Stream<MessageEnvelope> read(InputDescriptor inputDescriptor) =>
      registry.readers[inputDescriptor.reader.type]!
          .call(inputDescriptor.reader.config)
          .read(inputDescriptor.path);

  /// Write the conversation stream to all outputs.
  /// Performs any postprocessing steps for each output.
  /// yields OutputDescriptor for each completed output.
  Stream<OutputDescriptor> writeAll(Stream<Conversation> conversations) async* {
    final List<Conversation> collected = await conversations.toList();

    for (OutputDescriptor descriptor in repository.descriptor.outputs) {
      await write(postProcess(Stream.fromIterable(collected), descriptor),
              descriptor)
          .drain();
      yield descriptor;
    }
  }
}
