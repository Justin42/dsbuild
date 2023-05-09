import 'dart:io';

import 'package:logging/logging.dart';

import 'api.dart';
import 'config.dart';
import 'model/descriptor.dart';
import 'reader/bluemoon_reader.dart';
import 'reader/vicuna_reader.dart';
import 'registry.dart';
import 'repository.dart';
import 'transformer/transformers.dart';
import 'writer/vicuna_writer.dart';

class DsBuild extends DsBuildApi {
  static Logger log = Logger("dsbuild");

  static const Map<String, Type> builtinPreprocessors = {
    'ExactMatch': ExactMatch,
    'Punctuation': Punctuation,
    'Trim': Trim,
    'Unicode': Unicode
  };

  static const Map<String, Type> builtinReaders = {
    'bluemoon': BluemoonReader,
    'vicuna': VicunaReader,
  };

  static const Map<String, Type> builtinWriters = {'vicuna': VicunaWriter};

  DsBuild(DatasetDescriptor descriptor,
      {Config config = const Config(),
      Map<String, Type> readers = builtinReaders,
      Map<String, Type> writers = builtinWriters,
      Map<String, Type> preprocessors = builtinPreprocessors})
      : super(config, Repository(descriptor),
            Registry(readers, writers, preprocessors: preprocessors));

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
}
