import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dsbuild/model/conversation.dart';

import 'writer.dart';

class FastChatWriter extends Writer {
  const FastChatWriter(super.config);

  @override
  Stream<Conversation> write(Stream<Conversation> conversations,
      String destination) async* {
    IOSink ioSink = await File(destination)
        .create(recursive: true)
        .then((value) => value.openWrite());
    ioSink.writeln("[");

    yield* conversations.map((event) {
      ioSink
          .write(jsonEncode({'id': event.id, 'conversations': event.messages}));
      ioSink.write(',\n');
      return event;
    });

    ioSink.writeln("]");
    ioSink.close();
  }
}
