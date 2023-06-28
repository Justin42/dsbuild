import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../../conversation.dart';
import '../../transformers.dart';

Logger _log = Logger("dsbuild");

/// Output JSON data formatted for FastChat
class FastChatOutput extends ConversationTransformer {
  /// Output file
  final File file;

  /// Indents
  final int indent;

  /// Create a new instance
  FastChatOutput(super.config)
      : indent = config['indent'] ?? 0,
        file = File(config['path'].toString());

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    JsonEncoder encoder =
        indent == 0 ? JsonEncoder() : JsonEncoder.withIndent(' ' * indent);
    IOSink ioSink =
        await file.create(recursive: true).then((value) => value.openWrite());
    ioSink.writeln("[");
    StringBuffer buffer = StringBuffer();
    yield* stream
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      for (Conversation conversation in data) {
        if (buffer.isEmpty) {
          buffer.write(encoder.convert({
            'id': conversation.id,
            'conversations': conversation.messages.toJson((p0) => p0.toMap())
          }));
        } else {
          ioSink.write(buffer);
          ioSink.write(",\n");
          buffer.clear();
          buffer.write(encoder.convert({
            'id': conversation.id,
            'conversations': conversation.messages.toJson((p0) => p0.toMap())
          }));
        }
      }
      sink.add(data);
    }, handleDone: (sink) async {
      ioSink.writeln(buffer);
      ioSink.write("]");
      await ioSink.flush();
      await ioSink.close();
      sink.close();
      buffer.clear();
      _log.info(
          "Output finalized: $runtimeType ${p.relative(file.path, from: Directory.current.path)}");
    }));
  }
}
