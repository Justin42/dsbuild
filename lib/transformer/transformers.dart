import 'dart:async';
import 'dart:collection';

import 'package:dsbuild/transformer/postprocessor.dart';
import 'package:html/parser.dart';

import '../model/conversation.dart';
import 'preprocessor.dart';

class HtmlStrip extends Preprocessor {
  HtmlStrip(super.config);

  @override
  String get description => "Strip HTML";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(
            data.copyWithValue(parseFragment(data.message.value).text ?? ""));
      });
}

class Trim extends Preprocessor {
  const Trim(super.config);

  @override
  String get description => "Trim whitespace and trailing line endings.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.copyWithValue(data.message.value.trim()));
      });
}

class RegexReplace extends Preprocessor {
  RegexReplace(super.config)
      : regex = [
          for (List r in config['replacements'])
            RegExp(r[0],
                multiLine: config['multiLine'] ?? false,
                caseSensitive: config['caseSensitive'] ?? true,
                unicode: config['unicode'] ?? false,
                dotAll: config['dotAll'] ?? false)
        ];
  final List<RegExp> regex;

  @override
  String get description => "Regex pattern replacement";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        String newText = data.value;
        for (int i = 0; i < regex.length; i++) {
          newText = newText.replaceAll(regex[i], config['replacements'][i][1]);
        }
        sink.add(data.copyWithValue(newText));
      });
}

class ExactReplace extends Preprocessor {
  List replacements;

  ExactReplace(super.config) : replacements = config['replacements'];

  @override
  String get description => "Simple substitution on exact match.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        String newText = data.value;
        for (List replacement in replacements) {
          newText = newText.replaceAll(replacement[0], replacement[1]);
        }
        sink.add(data.copyWithValue(newText));
      });
}

enum ExactMatchAction { drop }

class ExactMatch extends Preprocessor {
  List<String> patterns;
  ExactMatchAction action;
  bool caseSensitive;

  ExactMatch(super.config)
      : patterns = [for (String patterns in config['patterns']) patterns],
        action = ExactMatchAction.values.byName(config['action']),
        caseSensitive = config['caseSensitive'];

  @override
  String get description {
    switch (action) {
      case ExactMatchAction.drop:
        return "Drop messages that exactly match the provided pattern.";
        break;
    }
  }

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        for (String pattern in patterns) {
          switch (action) {
            case ExactMatchAction.drop:
              if (caseSensitive &&
                  (data.value.toLowerCase() == pattern.toLowerCase())) {
                continue;
              } else if (data.value == pattern) {
                continue;
              }
              break;
          }
          sink.add(data);
          break;
        }
      });
}

class Punctuation extends Preprocessor {
  const Punctuation(super.config);

  @override
  String get description =>
      "Trivial adjustments to whitespace and punctuation.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleDone: (sink) {
            sink.close();
          });
}

class Unicode extends Preprocessor {
  const Unicode(super.config);

  @override
  String get description => "Prune or strip messages containing unicode.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleDone: (sink) {
            sink.close();
          });
}*/
