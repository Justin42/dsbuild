import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../conversation.dart';
import '../conversation_transformer.dart';

/// Replace matches with a substitution.
class ExactReplace extends ConversationTransformer {
  /// Patterns and their substitutions.
  final IList<({String match, String replace})> replacements;

  /// Match recursively
  final bool recursive;

  /// Constructs a new instance
  ExactReplace(super.config)
      : replacements = IList([
          for (List replacement in config['replacements'])
            (match: replacement[0], replace: replacement[1])
        ]),
        recursive = config['recursive'] ?? false;

  @override
  String get description => "Simple substitution on exact match.";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> data in stream) {
      IList<Conversation> conversations = IList(data);
      for (var (int i, Conversation conversation) in data.indexed) {
        List<Message> messages = conversation.messages.unlockLazy;
        bool modified = false;
        for (int i = 0; i < conversation.messages.length; i++) {
          Message message = conversation.messages[i];
          String lastText = message.value;
          bool hasMatches = false;
          do {
            hasMatches = false;
            for (int i = 0; i < replacements.length; i++) {
              var (:match, :replace) = replacements[i];
              String text = lastText.replaceAll(match, replace);
              if (!identical(text, lastText)) {
                lastText = text;
                hasMatches = true;
                modified = true;
              }
            }
          } while (hasMatches && recursive);
          if (!identical(lastText, message.value)) {
            messages[i] = message.copyWith(value: lastText);
          }
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
