import 'reader/reader.dart';
import 'transformer/postprocessor.dart';
import 'transformer/preprocessor.dart';
import 'writer/writer.dart';

class Registry {
  final Map<String, Reader Function(Map)> readers;
  final Map<String, Preprocessor Function(Map)> preprocessors;
  final Map<String, Postprocessor Function(Map)> postprocessors;
  final Map<String, Writer Function(Map<String, dynamic>)> writers;

  const Registry(this.readers, this.writers,
      {this.preprocessors = const {}, this.postprocessors = const {}});

  void registerReader(String name, Reader Function(Map) builder) {
    readers[name] = builder;
  }

  void registerPreprocessor(String name, Preprocessor Function(Map) builder) {
    preprocessors[name] = builder;
  }

  void registerPostprocessor(String name, Postprocessor Function(Map) builder) {
    postprocessors[name] = builder;
  }

  void registerWriter(String name, Writer Function(Map) builder) {
    writers[name] = builder;
  }
}
