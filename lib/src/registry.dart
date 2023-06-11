import 'package:dsbuild/src/transformers/conversation_transformer.dart';

/// Registry for transformers
class Registry {
  /// Transformers
  final Map<String, ConversationTransformerBuilderFn> transformers;

  /// Create a new instance
  const Registry(this.transformers);

  /// Empty registry
  Registry.empty() : transformers = const {};

  /// Returns true if the transformers map is empty.
  bool get isEmpty => transformers.isEmpty;

  /// Register a new transformer.
  void registerTransformer(
      String name, ConversationTransformerBuilderFn builder) {
    transformers[name] = builder;
  }
}
