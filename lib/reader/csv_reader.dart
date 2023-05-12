import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

import '../model/conversation.dart';
import 'reader.dart';

class CsvReader extends Reader {
  const CsvReader(super.config);

  @override
  Stream<MessageEnvelope> read(String source) async* {
    Stream<String> csvChunks = Utf8Decoder().bind(File(source).openRead());

    int convoIdCol = 0;
    int fromCol = 0;
    int messageCol = 0;
    bool header = true;

    yield* csvChunks
        .transform(CsvToListConverter())
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      // Extract column indexes for configured columns
      // The config could just take col indices instead.
      // This is more human friendly.
      if (header) {
        for (int i = 0; i < data.length; i++) {
          if (data[i] == config['conversation']) {
            convoIdCol = i;
          } else if (data[i] == config['from']) {
            fromCol = i;
          } else if (data[i] == config['message']) {
            messageCol = i;
          }
        }
        header = false;
      } else {
        sink.add(MessageEnvelope(
            Message(data[fromCol], data[messageCol]), data[convoIdCol]));
      }
    }));
  }
}
