import 'dart:async';
import 'dart:io';

import 'package:dsbuild/transformer/postprocessor.dart';
import 'package:dsbuild/writer/dsbuild_writer.dart';
import 'package:logging/logging.dart';

import 'config.dart';
import 'model/conversation.dart';
import 'model/descriptor.dart';
import 'reader/bluemoon_reader.dart';
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

  static final Map<String, Preprocessor Function(Map<String, dynamic>)>
      builtinPreprocessors = {
    'ExactMatch': (config) => t.ExactMatch(config),
    'Punctuation': (config) => t.Punctuation(config),
    'Trim': (config) => t.Trim(config),
    'Unicode': (config) => t.Unicode(config)
  };

  static final Map<String, Postprocessor Function(Map<String, dynamic>)>
      builtinPostprocessors = {
    //'Unicode': (config) => Unicode(config),
  };

  static final Map<String, Reader Function(Map<String, dynamic>)>
      builtinReaders = {
    'bluemoon': (config) => BluemoonReader(config),
    'fastchat': (config) => FastChatReader(config),
  };

  static final Map<String, Writer Function(Map<String, dynamic>)>
      builtinWriters = {
    'fastchat': (config) => FastChatWriter(config),
    'dsbuild': (config) => DsBuildWriter(config)
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
      if (!registry.readers.containsKey(input.format)) {
        errors.add("No reader matching type '${input.format}'");
      }
    }

    // Verify postprocessors
    for (OutputDescriptor output in repository.descriptor.outputs) {
      for (StepDescriptor step in output.steps) {
        if (!registry.postprocessors.containsKey(step.type)) {
          errors.add("No postprocessor matching type '${output.format}");
        }
      }
    }

    // Verify writers
    for (OutputDescriptor output in repository.descriptor.outputs) {
      if (!registry.writers.containsKey(output.format)) {
        errors.add("No writer matching type '${output.format}'");
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
      if (await File(input.path).exists()) {
        log.fine("Skipping fetch for existing input file '${input.path}'");
      } else {
        if (!['http', 'https'].contains(input.source.scheme)) {
          log.severe("Unhandled URI input: '${input.source}'");
          continue;
        }
        log.info("Retrieving ${input.source}");
        final request = await client.getUrl(input.source);
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
      pipeline = pipeline
          .transform(registry.postprocessors[step.type]!.call({}).transformer);
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
        } else {
          convoMessages.add(Message(data.from, data.value));
        }
      });
      yield* messageStream.transform(concatenatingTransformer);
    }
  }

  /// Transform each input according to it's InputDescriptor.
  /// The transformation output is concatenated, in the order of input, into a single Conversation stream.
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
      registry.writers[output.format]!
          .call({}).write(conversations, output.path);

  /// Read the input specified by the InputDescriptor.
  /// yields MessageEnvelope for each message.
  Stream<MessageEnvelope> read(InputDescriptor inputDescriptor) =>
      registry.readers[inputDescriptor.format]!
          .call({}).read(inputDescriptor.path);

  /// Write the conversation stream to all outputs.
  /// yields OutputDescriptor for each output.
  Stream<OutputDescriptor> writeAll(Stream<Conversation> conversations) async* {
    final List<Conversation> collected = await conversations.toList();

    for (OutputDescriptor descriptor in repository.descriptor.outputs) {
      await write(Stream.fromIterable(collected), descriptor).drain();
      yield descriptor;
    }
  }
}
