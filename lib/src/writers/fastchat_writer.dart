import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../conversation.dart';
import '../writer.dart';

class FastChatWriter extends Writer {
  int indent;

  FastChatWriter(super.config) : indent = config['indent'] ?? 0;

  @override
  Stream<Conversation> write(
      Stream<Conversation> conversations, String destination) async* {
    JsonEncoder encoder =
        indent == 0 ? JsonEncoder() : JsonEncoder.withIndent(' ' * indent);
    IOSink ioSink = await File(destination)
        .create(recursive: true)
        .then((value) => value.openWrite());
    ioSink.writeln("[");
    StringBuffer buffer = StringBuffer();
    yield* conversations
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      if (buffer.isEmpty) {
        buffer.write(
            encoder.convert({'id': data.id, 'conversations': data.messages}));
      } else {
        ioSink.write(buffer);
        ioSink.write(",\n");
        buffer.clear();
        buffer.write(
            encoder.convert({'id': data.id, 'conversations': data.messages}));
      }
      sink.add(data);
    }, handleDone: (sink) async {
      ioSink.writeln(buffer);
      ioSink.write("]");
      await ioSink.flush();
      buffer.clear();
      ioSink.close();
      sink.close();
    }));
  }
}
