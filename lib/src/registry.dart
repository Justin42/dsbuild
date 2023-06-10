import 'transformers/conversation_transformer.dart';

/// Registry for transformers
class Registry {
  /// Transformers
  final Map<String, ConversationTransformer Function(Map)> transformers;

  /// Create a new instance
  const Registry({this.transformers = const {}});

  /// Register a new transformer.
  void registerTransformer(
      String name, ConversationTransformer Function(Map) builder) {
    transformers[name] = builder;
  }
}
