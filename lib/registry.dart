import 'package:dsbuild/transformer/postprocessor.dart';

import 'reader/reader.dart';
import 'transformer/preprocessor.dart';
import 'writer/writer.dart';

class Registry {
  final Map<String, Reader Function(Map<String, dynamic>)> readers;
  final Map<String, Writer Function(Map<String, dynamic>)> writers;
  final Map<String, Preprocessor Function(Map<String, dynamic>)> preprocessors;
  final Map<String, Postprocessor Function(Map<String, dynamic>)>
      postprocessors;

  const Registry(this.readers, this.writers,
      {this.preprocessors = const {}, this.postprocessors = const {}});

  void registerPreprocessor(
      String name, Preprocessor Function(Map<String, dynamic>) builder) {
    preprocessors[name] = builder;
  }

  void registerReader(
      String name, Reader Function(Map<String, dynamic>) builder) {
    readers[name] = builder;
  }
}
