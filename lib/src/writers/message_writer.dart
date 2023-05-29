import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import '../conversation.dart';
import '../writer.dart';

Logger _log = Logger("dsbuild");

class RawMessageWriter extends Writer {
  bool escape;

  RawMessageWriter(super.config) : escape = config['escape'] ?? false;

  @override
  Stream<Conversation> write(
      Stream<Conversation> conversations, String destination) async* {
    IOSink ioSink = await File(destination)
        .create(recursive: true)
        .then((value) => value.openWrite());
    yield* conversations
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      for (Message message in data.messages) {
        if (escape) {
          ioSink.writeln(message.value.replaceAll("\n", r"\n"));
        } else {
          ioSink.writeln(message.value);
        }
      }
      sink.add(data);
    }, handleDone: (sink) async {
      await ioSink.flush();
      ioSink.close();
      sink.close();
      _log.info("Output finalized: $runtimeType $destination");
    }));
  }
}
