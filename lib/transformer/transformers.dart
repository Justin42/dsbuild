import 'dart:async';
import 'dart:collection';
import 'dart:io';

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
  final List<RegExp> regex;

  RegexReplace(super.config)
      : regex = [
          for (List r in config['replacements'])
            RegExp(r[0],
                multiLine: config['multiLine'] ?? false,
                caseSensitive: config['caseSensitive'] ?? true,
                unicode: config['unicode'] ?? false,
                dotAll: config['dotAll'] ?? false)
        ];

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

class RegexExtract extends Preprocessor {
  final List<RegExp> regex;
  final File file;
  IOSink? ioSink;
  final bool escape;

  RegexExtract(super.config)
      : regex = [
          for (String pattern in config['patterns'])
            RegExp(pattern,
                multiLine: config['multiLine'] ?? false,
                caseSensitive: config['caseSensitive'] ?? true,
                unicode: config['unicode'] ?? false,
                dotAll: config['dotAll'] ?? false)
        ],
        file = File(config['path']),
        //TODO: buffer = config['buffer'] ?? false,
        escape = config['escape'];

  @override
  String get description => "Extract content matching pattern.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        // convoId / username:
        // match1
        // match2
        // ...
        // \n
        ioSink ??= file.openWrite(
            mode: config['overwrite'] ? FileMode.writeOnly : FileMode.append);
        bool matches = false;
        for (RegExp pattern in regex) {
          data.value.replaceAllMapped(pattern, (match) {
            if (!matches) {
              ioSink?.writeln("${data.conversationId} / ${data.from}:");
              matches = true;
            }
            if (escape) {
              ioSink!.writeln(data.value
                  .substring(match.start, match.end)
                  .replaceAll("\n", r"\n"));
            } else {
              ioSink!.writeln(data.value.substring(match.start, match.end));
            }
            return match.input;
          });
        }
        if (matches) {
          ioSink!.writeln();
        }
        sink.add(data);
      }, handleDone: (sink) async {
        await ioSink?.flush();
        await ioSink?.close();
        sink.close();
      });
}

class ExactReplace extends Preprocessor {
  final List replacements;
  final bool recursive;

  ExactReplace(super.config)
      : replacements = config['replacements'],
        recursive = config['recursive'] ?? false;

  @override
  String get description => "Simple substitution on exact match.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        String lastText = data.value;
        List<bool> hasMatches = List.filled(replacements.length, false);
        do {
          for (int i = 0; i < replacements.length; i++) {
            hasMatches[i] = false;
            String text =
                lastText.replaceAll(replacements[i][0], replacements[i][1]);
            if (text != lastText) {
              lastText = text;
              hasMatches[i] = true;
            }
          }
        } while (hasMatches.contains(true) && recursive);
        sink.add(data.copyWithValue(lastText));
      });
}

enum ExactMatchAction { drop }

class FullMatch extends Preprocessor {
  final List<String> patterns;
  final ExactMatchAction action;
  final bool caseSensitive;

  FullMatch(super.config)
      : patterns = [for (String patterns in config['patterns']) patterns],
        action = ExactMatchAction.values.byName(config['action']),
        caseSensitive = config['caseSensitive'] ?? true;

  @override
  String get description {
    switch (action) {
      case ExactMatchAction.drop:
        return "Drop messages that exactly match the provided pattern.";
    }
  }

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        bool skip = false;
        for (String pattern in patterns) {
          switch (action) {
            case ExactMatchAction.drop:
              if (!caseSensitive &&
                  (data.value.toLowerCase() == pattern.toLowerCase())) {
                skip = true;
                break;
              } else if (data.value == pattern) {
                skip = true;
                break;
              }
          }
          if (skip) break;
        }
        if (!skip) {
          sink.add(data);
        }
      });
}

class Participants extends Postprocessor {
  final int min;
  final int? max;
  final bool alternating;

  Participants(super.config)
      : min = config['min'] ?? 0,
        max = config['max'],
        alternating = config['alternating'] ?? false;

  @override
  String get description =>
      "Filter conversations according to participant count.";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        String? lastParticipant;
        HashSet<String> participants = HashSet();
        bool skip = false;
        for (Message message in data.messages) {
          if (lastParticipant == message.from && alternating) {
            skip = true;
            break;
          }
          participants.add(message.from);
          lastParticipant = message.from;
          if (max != null && participants.length > max!) {
            skip = true;
            break;
          }
        }
        if (participants.length < min) skip = true;
        if (!skip) {
          sink.add(data);
        }
      });
}

/*
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
