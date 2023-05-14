import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dsbuild/model/conversation.dart';

import 'writer.dart';

class FastChatWriter extends Writer {
  const FastChatWriter(super.config);

  @override
  Stream<Conversation> write(
      Stream<Conversation> conversations, String destination) async* {
    IOSink ioSink = await File(destination)
        .create(recursive: true)
        .then((value) => value.openWrite());
    ioSink.writeln("[");
    StringBuffer buffer = StringBuffer();
    yield* conversations
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      if (buffer.isEmpty) {
        buffer
            .write(jsonEncode({'id': data.id, 'conversations': data.messages}));
      } else {
        ioSink.write(buffer);
        ioSink.write(",\n");
        buffer.clear();
        buffer
            .write(jsonEncode({'id': data.id, 'conversations': data.messages}));
      }
      sink.add(data);
    }, handleDone: (sink) {
      ioSink.writeln(buffer);
      ioSink.write("]");
      buffer.clear();
      ioSink.close();
    }));
  }
}
