import 'dart:async';

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
        sink.add(data.copyWith(
            message: data.message
                .copyWith(value: parseFragment(data.message.value).text)));
      });
}

class Trim extends Preprocessor {
  const Trim(super.config);

  @override
  String get description => "Trim whitespace and trailing line endings.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.copyWith(
            message: data.message.copyWith(value: data.message.value.trim())));
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
        sink.add(data.copyWith(message: data.message.copyWith(value: newText)));
      });
}

/*class ExactReplace extends Preprocessor {
  const ExactReplace(super.config);

  @override
  String get description =>
      "Prune or strip messages exactly matching the provided text";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data));
}

class PatternMatch extends Preprocessor {
  const PatternMatch(super.config);

  @override
  String get description =>
      "Prune or strip messages matching the provided pattern.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data));
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
