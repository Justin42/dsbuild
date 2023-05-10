import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../model/conversation.dart';
import 'reader.dart';

class VicunaReader extends Reader {
  const VicunaReader(super.config);

  @override
  Stream<MessageEnvelope> read(String source) async* {
    List<dynamic> json = jsonDecode(await File(source).readAsString());

    yield* Stream.fromIterable(json).transform(
        StreamTransformer.fromHandlers(handleData: (conversation, messageSink) {
      for (Map<String, String> message in conversation['conversations']) {
        messageSink.add(MessageEnvelope(
            Message(message['from']!, message['value']!), conversation['id']));
      }
    }));
  }
}
