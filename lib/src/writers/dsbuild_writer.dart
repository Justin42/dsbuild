import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../conversation.dart';
import '../writer.dart';

class DsBuildWriter extends Writer {
  const DsBuildWriter(super.config);

  @override
  Stream<Conversation> write(
      Stream<Conversation> conversations, String destination) async* {
    IOSink ioSink = await File(destination)
        .create(recursive: true)
        .then((value) => value.openWrite());
    ioSink.writeln("[");

    yield* conversations.map((event) {
      ioSink.write(jsonEncode(event.toJson()));
      ioSink.write(',\n');
      return event;
    });

    ioSink.writeln("]");
    ioSink.close();
  }
}
