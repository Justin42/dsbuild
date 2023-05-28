import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:logging/logging.dart';

import '../conversation.dart';
import 'postprocessor.dart';
import 'preprocessor.dart';

Logger _log = Logger("dsbuild/transformers");

class HtmlStrip extends Preprocessor {
  final bool caseSensitive;
  final List<Pattern> stripAnchorPatterns;
  final String anchorSelector;

  int strippedAnchors = 0;

  HtmlStrip(super.config)
      : caseSensitive = config['caseSensitive'] ?? true,
        stripAnchorPatterns = config['stripAnchorPatterns'] != null
            ? [for (String pattern in config['stripAnchorPatterns']) pattern]
            : [],
        anchorSelector = config['anchorSelector'] ?? "a, img";

  @override
  String get description => "Strip HTML";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        DocumentFragment fragment = parseFragment(data.message.value);
        if (stripAnchorPatterns.isNotEmpty) {
          List<Element> removals = [];
          for (Element child in fragment.querySelectorAll(anchorSelector)) {
            for (Pattern pattern in stripAnchorPatterns) {
              if ((caseSensitive && child.text.contains(pattern)) ||
                  (caseSensitive &&
                      child.text.toLowerCase().contains(pattern))) {
                removals.add(child);
                break;
              }
            }
          }
          strippedAnchors += removals.length;
          for (Node node in removals) {
            node.remove();
          }
        }

        sink.add(data.copyWithValue(fragment.text ?? ""));
      }, handleDone: (sink) {
        _log.finer("$runtimeType stripped $strippedAnchors anchor texts.");
        sink.close();
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

class RegexReplacePost extends Postprocessor {
  final List<RegExp> regex;

  RegexReplacePost(super.config)
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
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.copyWith(
            messages: data.messages.map((e) {
          for (int i = 0; i < regex.length; i++) {
            e = e.copyWith(
                value:
                    e.value.replaceAll(regex[i], config['replacements'][i][1]));
          }
          return e;
        }).toList()));
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

class ExactReplacePost extends Postprocessor {
  final List replacements;
  final bool recursive;

  ExactReplacePost(super.config)
      : replacements = config['replacements'],
        recursive = config['recursive'] ?? false;

  @override
  String get description => "Simple substitution on exact match.";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        List<Message> messages =
            List.filled(data.messages.length, Message.empty());
        for (int i = 0; i < data.messages.length; i++) {
          String lastText = data.messages[i].value;
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
          messages[i] = data.messages[i].copyWith(value: lastText);
        }
        sink.add(data.copyWith(messages: messages));
      });
}

enum FullMatchAction { drop }

class FullMatch extends Preprocessor {
  final List<String> patterns;
  final FullMatchAction action;
  final bool caseSensitive;

  FullMatch(super.config)
      : patterns = [for (String patterns in config['patterns']) patterns],
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
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        bool skip = false;
        for (String pattern in patterns) {
          switch (action) {
            case FullMatchAction.drop:
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

class FullMatchPost extends Postprocessor {
  final List<String> patterns;
  final FullMatchAction action;
  final bool caseSensitive;

  FullMatchPost(super.config)
      : patterns = [for (String patterns in config['patterns']) patterns],
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
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        List<Message> messages = [];
        for (int i = 0; i < data.messages.length; i++) {
          bool skip = false;
          for (String pattern in patterns) {
            switch (action) {
              case FullMatchAction.drop:
                if (!caseSensitive &&
                    (data.messages[i].value.toLowerCase() ==
                        pattern.toLowerCase())) {
                  skip = true;
                  break;
                } else if (data.messages[i].value == pattern) {
                  skip = true;
                  break;
                }
            }
            if (skip) break;
          }
          if (!skip) {
            messages.add(data.messages[i]);
          }
        }
        sink.add(data.copyWith(messages: messages));
      });
}

class Participants extends Postprocessor {
  final int min;
  final int? max;
  final bool alternating;

  int _skipped = 0;

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
        } else {
          _skipped += 1;
        }
      }, handleDone: (sink) {
        _log.finer(
            "${runtimeType.toString()} dropped $_skipped conversations.");
        sink.close();
      });
}

class RenameParticipants extends Postprocessor {
  List<String> names;

  RenameParticipants(super.config)
      : names = [for (var name in config['names']) name as String];

  @override
  String get description => "Rename participants";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        Map<String, String> renameMap = {};
        List<Message> messages = [];
        for (final Message message in data.messages) {
          if (!renameMap.containsKey(message.from)) {
            if (renameMap.length < names.length) {
              messages.add(message.copyWith(from: names[renameMap.length]));
              renameMap[message.from] = names[renameMap.length];
            } else {
              messages.add(message);
            }
          } else {
            messages.add(message.copyWith(from: renameMap[message.from]));
          }
        }
        sink.add(data.copyWith(messages: messages));
      });
}

class EncodingPre extends Preprocessor {
  String codecName;
  String invalidChar;
  Codec<String, List<int>>? codec;

  EncodingPre(super.config)
      : invalidChar = config['invalid'] ?? r'�',
        codecName = config['codec'] {
    if (codecName == 'us-ascii') {
      codec = AsciiCodec(allowInvalid: true);
    } else if (codecName == 'utf-8') {
      codec = Utf8Codec(allowMalformed: true);
    } else if (codecName == 'iso-8859-1') {
      codec = Latin1Codec(allowInvalid: true);
    }
  }

  @override
  String get description =>
      "Effectively strips character codes not present in the specified encoding. Does not affect output encoding.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.copyWithValue(
            codec!.decode(data.value.codeUnits).replaceAll(r'�', invalidChar)));
      });
}

class EncodingPost extends Postprocessor {
  String codecName;
  String invalidChar;
  Codec<String, List<int>>? codec;

  EncodingPost(super.config)
      : invalidChar = config['invalid'] ?? r'�',
        codecName = config['codec'] {
    if (codecName == 'us-ascii') {
      codec = AsciiCodec(allowInvalid: true);
    } else if (codecName == 'utf-8') {
      codec = Utf8Codec(allowMalformed: true);
    } else if (codecName == 'iso-8859-1') {
      codec = Latin1Codec(allowInvalid: true);
    }
  }

  @override
  String get description =>
      "Effectively strips character codes not present in the specified encoding. Does not affect output encoding.";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.copyWith(
            messages: data.messages
                .map<Message>((message) => message.copyWith(
                    value: codec!
                        .decode(message.value.codeUnits)
                        .replaceAll(r'�', invalidChar)))
                .toList(growable: false)));
      });
}

class TrimPost extends Postprocessor {
  const TrimPost(super.config);

  @override
  String get description => "Trim whitespace and trailing line endings.";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.copyWith(
            messages: data.messages
                .map((message) => message.copyWith(value: message.value.trim()))
                .toList()));
      });
}
