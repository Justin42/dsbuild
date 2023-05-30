import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../conversation.dart';
import '../postprocessor.dart';
import '../preprocessor.dart';

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
