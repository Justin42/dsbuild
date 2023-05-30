import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../conversation.dart';
import '../postprocessor.dart';
import '../preprocessor.dart';

class ExactReplace extends Preprocessor {
  final IList<({String match, String replace})> replacements;
  final bool recursive;

  ExactReplace(super.config)
      : replacements = IList([
          for (List replacement in config['replacements'])
            (match: replacement[0], replace: replacement[1])
        ]),
        recursive = config['recursive'] ?? false;

  @override
  String get description => "Simple substitution on exact match.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        String lastText = data.value;
        bool hasMatches = false;
        bool modified = false;
        do {
          hasMatches = false;
          for (var (:match, :replace) in replacements) {
            String text = lastText.replaceAll(match, replace);
            if (!identical(text, lastText)) {
              lastText = text;
              hasMatches = true;
              modified = true;
            }
          }
        } while (hasMatches && recursive);
        if (modified) {
          sink.add(data.copyWithValue(lastText));
        } else {
          sink.add(data);
        }
      });
}

class ExactReplacePost extends Postprocessor {
  final IList<({String match, String replace})> replacements;
  final bool recursive;

  ExactReplacePost(super.config)
      : replacements = IList([
          for (List replacement in config['replacements'])
            (match: replacement[0], replace: replacement[1])
        ]),
        recursive = config['recursive'] ?? false;

  @override
  String get description => "Simple substitution on exact match.";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        List<Message> messages = data.messages.unlockLazy;
        bool modified = false;
        for (int i = 0; i < data.messages.length; i++) {
          Message message = data.messages[i];
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
          sink.add(data.copyWith(messages: messages.lock));
        } else {
          sink.add(data);
        }
      });
}
