import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../conversation.dart';
import '../conversation_transformer.dart';

/// Replace regex pattern with provided substitution.
class RegexReplace extends ConversationTransformer {
  /// RegExp patterns
  final IList<RegExp> regex;

  /// Constructs a new instance
  RegexReplace(super.config)
      : regex = [
          for (List r in config['replacements'])
            RegExp(r[0],
                multiLine: config['multiLine'] ?? false,
                caseSensitive: config['caseSensitive'] ?? true,
                unicode: config['unicode'] ?? false,
                dotAll: config['dotAll'] ?? false)
        ].lock;

  @override
  String get description => "Regex pattern replacement";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> batch in stream) {
      IList<Conversation> conversations = batch.lock;
      for (var (int i, Conversation conversation) in batch.indexed) {
        conversations = conversations.replace(i,
            conversation.copyWith(messages: conversation.messages.map((e) {
          for (int i = 0; i < regex.length; i++) {
            e = e.copyWith(
                value:
                    e.value.replaceAll(regex[i], config['replacements'][i][1]));
          }
          return e;
        })));
      }
      yield conversations.unlockLazy;
    }
  }
}
