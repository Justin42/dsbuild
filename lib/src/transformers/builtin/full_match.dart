import 'dart:async';

import 'package:dsbuild/src/transformers/conversation_transformer.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../conversation.dart';

/// Action to perform when a match has been found.
enum FullMatchAction {
  /// Drop the element
  drop
}

/// Drop messages that exactly matches the provided pattern.
class FullMatchPost extends ConversationTransformer {
  /// Patterns to match
  final IList<String> patterns;

  /// Action to perform on match.
  final FullMatchAction action;

  /// Case sensitive matching
  final bool caseSensitive;

  /// Constructs a new instance
  FullMatchPost(super.config)
      : patterns = [
          for (String patterns in config['patterns'])
            config['caseSensitive'] ?? true ? patterns : patterns.toLowerCase()
        ].lock,
        action = FullMatchAction.values.byName(config['action']),
        caseSensitive = config['caseSensitive'] ?? true;

  @override
  String get description {
    switch (action) {
      case FullMatchAction.drop:
        return "Drop messages that exactly match the provided pattern.";
    }
  }

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> batch in stream) {
      IList<Conversation> conversations = batch.lock;
      for (var (int i, Conversation conversation) in batch.indexed) {
        bool modified = false;
        IList<Message> messages = conversation.messages;
        switch (action) {
          case FullMatchAction.drop:
            messages = messages.retainWhere((element) {
              String compareValue =
                  caseSensitive ? element.value : element.value.toLowerCase();
              for (String pattern in patterns) {
                if (compareValue == pattern) {
                  modified = true;
                  return false;
                }
              }
              return true;
            });
            break;
        }
        if (modified) {
          conversations = conversations.replace(
              i, conversation.copyWith(messages: messages));
        }
      }
      yield conversations.unlockLazy;
    }
  }
}
