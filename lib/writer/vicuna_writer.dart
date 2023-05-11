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
    yield* conversations
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      sink.add(data);
      ioSink.write(jsonEncode(data.toJson()));
      ioSink.write(',\n');
    }, handleDone: (sink) {
      sink.close;
      ioSink.writeln("]");
      ioSink.close();
    }));
  }
}
