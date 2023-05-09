import 'dart:io';

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
  Stream<InputDescriptor> fetchRequirements() async* {
    HttpClient client = HttpClient();

    for (int i = 0; i < repository.descriptor.inputs.length; i++) {
      InputDescriptor input = repository.descriptor.inputs[i];
      if (input.uri.scheme != 'file') {
        log.fine("Skipping fetch for non-file destination URI '${input.uri}'");
      } else if (await File(input.uri.toFilePath()).exists()) {
        log.fine("Skipping fetch for existing input file '${input.uri}'");
      } else {
        Uri targetUri = input.uri;
        Uri? sourceUri = Uri.tryParse(input.source);
        if (sourceUri == null) {
          log.severe("Unable to parse URI for input '${input.source}'");
          continue;
        }
        final request = await client.getUrl(sourceUri);
        final response = await request.close();
        response.pipe(File.fromUri(targetUri).openWrite());
        yield input;
      }
    }

    client.close();
  }
}
