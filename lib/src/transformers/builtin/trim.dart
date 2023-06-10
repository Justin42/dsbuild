import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../conversation.dart';
import '../conversation_transformer.dart';

/// Trim whitespace
class TrimPost extends ConversationTransformer {
  /// Constructs a new instance
  const TrimPost(super.config);

  @override
  String get description => "Trim whitespace and trailing line endings.";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> batch in stream) {
      IList<Conversation> conversations = IList(batch);
      for (var (int i, Conversation conversation) in batch.indexed) {
        List<Message> messages = conversation.messages.unlockLazy;
        for (int i = 0; i < conversation.messages.length; i++) {
          Message message = conversation.messages[i];
          String text = message.value.trim();
          if (!identical(text, message.value)) {
            messages[i] = message.copyWith(value: text);
          }
        }
        conversations = conversations.replace(
            i, conversation.copyWith(messages: messages.lock));
      }
      yield conversations.unlockLazy;
    }
  }
}
