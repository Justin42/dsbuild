import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:logging/logging.dart';

import '../conversation.dart';
import 'postprocessor.dart';
import 'preprocessor.dart';

Logger _log = Logger("dsbuild/transformers");

class HtmlStrip extends Preprocessor {
  final bool caseSensitive;
  final IList<Pattern> stripAnchorPatterns;
  final String anchorSelector;

  int strippedAnchors = 0;

  HtmlStrip(super.config)
      : caseSensitive = config['caseSensitive'] ?? true,
        stripAnchorPatterns = config['stripAnchorPatterns'] != null
            ? IList([
                for (String pattern in config['stripAnchorPatterns'])
                  config['caseSensitive'] ?? true
                      ? pattern
                      : pattern.toLowerCase()
              ])
            : const IListConst([]),
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
        String text = data.message.value.trim();
        if (!identical(text, data.message.value)) {
          sink.add(data.copyWithValue(text));
        } else {
          sink.add(data);
        }
      });
}

class RegexReplace extends Preprocessor {
  final IList<RegExp> regex;

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
  final IList<RegExp> regex;

  RegexReplacePost(super.config)
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
        }).toIList()));
      });
}

class RegexExtract extends Preprocessor {
  final IList<RegExp> regex;
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
        ].lock,
        file = File(config['path']
            .toString()
            .replaceAll("%worker%", Isolate.current.debugName ?? '0')),
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
            mode: (config['overwrite'] ?? false)
                ? FileMode.writeOnly
                : FileMode.append);
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

enum FullMatchAction { drop }

class FullMatch extends Preprocessor {
  final IList<String> patterns;
  final FullMatchAction action;
  final bool caseSensitive;

  FullMatch(super.config)
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
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        switch (action) {
          case FullMatchAction.drop:
            bool skip = false;
            String compareValue =
                caseSensitive ? data.value : data.value.toLowerCase();
            for (String pattern in patterns) {
              switch (action) {
                case FullMatchAction.drop:
                  if (compareValue == pattern) {
                    skip = true;
                    break;
                  }
              }
              if (skip) break;
            }
            if (!skip) {
              sink.add(data);
            }
            break;
        }
      });
}

class FullMatchPost extends Postprocessor {
  final IList<String> patterns;
  final FullMatchAction action;
  final bool caseSensitive;

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
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        IList<Message> messages;
        switch (action) {
          case FullMatchAction.drop:
            messages = data.messages.retainWhere((element) {
              String compareValue =
                  caseSensitive ? element.value : element.value.toLowerCase();
              for (String pattern in patterns) {
                if (compareValue == pattern) {
                  return false;
                }
              }
              return true;
            });
            break;
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
        List<Message> messages = data.messages.unlock;
        for (int i = 0; i < data.messages.length; i++) {
          Message message = data.messages[i];
          if (!renameMap.containsKey(message.from)) {
            if (renameMap.length < names.length) {
              messages[i] = message.copyWith(from: names[renameMap.length]);
              renameMap[message.from] = names[renameMap.length];
            }
          } else {
            messages[i] = message.copyWith(from: renameMap[message.from]);
          }
        }
        sink.add(data.copyWith(messages: messages.lock));
      });
}

class EncodingPre extends Preprocessor {
  String codecName;
  String invalidChar;
  Codec<String, List<int>>? codec;

  EncodingPre(super.config)
      : invalidChar = config['invalid'] ?? r'�',
        codecName = config['codec'] {
    codec = switch (codecName) {
      'us-ascii' => AsciiCodec(allowInvalid: true),
      'utf-8' => Utf8Codec(allowMalformed: true),
      'iso-8859-1' => Latin1Codec(allowInvalid: true),
      _ => null
    };
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
    codec = switch (codecName) {
      'us-ascii' => AsciiCodec(allowInvalid: true),
      'utf-8' => Utf8Codec(allowMalformed: true),
      'iso-8859-1' => Latin1Codec(allowInvalid: true),
      _ => null
    };
  }

  @override
  String get description =>
      "Effectively strips character codes not present in the specified encoding. Does not affect output encoding.";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.copyWith(
            messages: data.messages.map<Message>((message) {
          String result = codec!.decode(message.value.codeUnits);
          result = result.contains(r'�')
              ? result.replaceAll(r'�', invalidChar)
              : result;
          return message.copyWith(value: result);
        }).toIList()));
      });
}

class TrimPost extends Postprocessor {
  const TrimPost(super.config);

  @override
  String get description => "Trim whitespace and trailing line endings.";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        List<Message> messages = data.messages.unlockLazy;
        bool modified = false;
        for (int i = 0; i < data.messages.length; i++) {
          Message message = data.messages[i];
          String text = message.value.trim();
          if (!identical(text, message.value)) {
            messages[i] = message.copyWith(value: text);
            modified = true;
          }
        }
        if (modified) {
          sink.add(data.copyWith(messages: messages.lock));
        } else {
          sink.add(data);
        }
      });
}
