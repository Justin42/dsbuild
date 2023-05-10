import 'reader/reader.dart';
import 'transformer/postprocessor.dart';
import 'transformer/preprocessor.dart';
import 'writer/writer.dart';

class Registry {
  final Map<String, Reader Function(Map<String, dynamic>)> readers;
  final Map<String, Preprocessor Function(Map<String, dynamic>)> preprocessors;
  final Map<String, Postprocessor Function(Map<String, dynamic>)>
      postprocessors;
  final Map<String, Writer Function(Map<String, dynamic>)> writers;

  const Registry(this.readers, this.writers,
      {this.preprocessors = const {}, this.postprocessors = const {}});

  void registerReader(
      String name, Reader Function(Map<String, dynamic>) builder) {
    readers[name] = builder;
  }

  void registerPreprocessor(
      String name, Preprocessor Function(Map<String, dynamic>) builder) {
    preprocessors[name] = builder;
  }

  void registerPostprocessor(
      String name, Postprocessor Function(Map<String, dynamic>) builder) {
    postprocessors[name] = builder;
  }

  void registerWriter(
      String name, Writer Function(Map<String, dynamic>) builder) {
    writers[name] = builder;
  }
}
