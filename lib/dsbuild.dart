import 'dart:io';

import 'package:dsbuild/model/conversation.dart';
import 'package:dsbuild/transformer/postprocessor.dart';
import 'package:logging/logging.dart';

import 'api.dart';
import 'config.dart';
import 'model/descriptor.dart';
import 'reader/bluemoon_reader.dart';
import 'reader/reader.dart';
import 'reader/vicuna_reader.dart';
import 'registry.dart';
import 'repository.dart';
import 'transformer/preprocessor.dart';
import 'transformer/transformers.dart';
import 'writer/vicuna_writer.dart';
import 'writer/writer.dart';

class DsBuild extends DsBuildApi {
  static Logger log = Logger("dsbuild");

  static final Map<String, Preprocessor Function(Map<String, dynamic>)>
      builtinPreprocessors = {
    'ExactMatch': (config) => ExactMatch(config),
    'Punctuation': (config) => Punctuation(config),
    'Trim': (config) => Trim(config),
    'Unicode': (config) => Unicode(config)
  };

  static final Map<String, Postprocessor Function(Map<String, dynamic>)>
      builtinPostprocessors = {
    //'Unicode': (config) => Unicode(config),
  };

  static final Map<String, Reader Function(Map<String, dynamic>)>
      builtinReaders = {
    'bluemoon': (config) => BluemoonReader(config),
    'vicuna': (config) => VicunaReader(config),
  };

  static final Map<String, Writer Function(Map<String, dynamic>)>
      builtinWriters = {
    'vicuna': (config) => VicunaWriter(config),
  };

  DsBuild(DatasetDescriptor descriptor,
      {Registry? registry, Config config = const Config()})
      : super(
            config,
            Repository(descriptor),
            registry ??
                Registry(builtinReaders, builtinWriters,
                    preprocessors: builtinPreprocessors,
                    postprocessors: builtinPostprocessors));

  @override
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

  @override
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

  @override
  Stream<Conversation> postProcess(
      Stream<Conversation> conversations, OutputDescriptor output) {
    // TODO: implement postProcess
    throw UnimplementedError();
  }

  @override
  Future<Stream<Conversation>> transform(InputDescriptor input) {
    // TODO: implement transform
    throw UnimplementedError();
  }

  @override
  Future<OutputDescriptor> write(
      List<Conversation> conversations, OutputDescriptor output) async {
    // Currently there is no config provided to writers.
    // This could be added in the OutputDescriptor and used here.
    Writer writer = registry.writers[output.format]!.call({});

    // Creates a stream of conversations and passes it through the postProcessor specified by the output descriptor.
    // The transformed stream is then passed through the writer unaltered.
    // There are no additional steps in the pipeline so the data is discarded.
    // The input is considered immutable during postprocessing.
    Stream<Conversation> processed =
        postProcess(Stream.fromIterable(conversations), output);
    await writer.write(processed, File(output.path).uri).drain();

    return output;
  }
}
