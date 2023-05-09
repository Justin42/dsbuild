class Registry {
  final Map<String, Type> readers;
  final Map<String, Type> writers;
  final Map<String, Type> preprocessors;
  final Map<String, Type> postprocessors;

  const Registry(this.readers, this.writers,
      {this.preprocessors = const {}, this.postprocessors = const {}});

  void registerPreprocessor(String name, Type preprocessor) {
    preprocessors[name] = preprocessor;
  }

  void registerReader(String name, Type reader) {
    readers[name] = reader;
  }
}
