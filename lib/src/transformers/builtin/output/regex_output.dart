import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../conversation.dart';
import '../../transformers.dart';

/// Output messages matching a [RegExp]
class RegexOutput extends ConversationTransformer {
  /// Regex patterns
  final IList<RegExp> regex;

  /// Output file
  final File file;

  /// Output sink
  IOSink? ioSink;

  /// Escape line endings
  final bool escape;

  /// Create a new instance
  RegexOutput(super.config)
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
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    ioSink ??= file.openWrite(
        mode: (config['overwrite'] ?? false)
            ? FileMode.writeOnly
            : FileMode.append);

    await for (List<Conversation> conversations in stream) {
      for (Conversation conversation in conversations) {
        for (Message message in conversation.messages) {
          bool matches = false;
          for (RegExp pattern in regex) {
            message.value.replaceAllMapped(pattern, (match) {
              if (!matches) {
                ioSink?.writeln("${conversation.id} / ${message.from}:");
                matches = true;
              }
              if (escape) {
                ioSink!.writeln(message.value
                    .substring(match.start, match.end)
                    .replaceAll("\n", r"\n"));
              } else {
                ioSink!
                    .writeln(message.value.substring(match.start, match.end));
              }
              return match.input;
            });
          }
          if (matches) {
            ioSink!.writeln();
          }
        }
      }
      yield conversations;
    }

    await ioSink?.flush();
    await ioSink?.close();
  }
}
