import 'package:dsbuild/src/conversation.dart';
import 'package:dsbuild/src/transformers/conversation_transformer.dart';

/// Collect statistics for all conversations.
class CollectStatistics extends ConversationTransformer {
  CollectStatistics(super.config);

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) {
    // TODO: implement bind
    throw UnimplementedError();
  }
}
