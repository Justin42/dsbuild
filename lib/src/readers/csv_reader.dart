import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

import '../conversation.dart';
import '../reader.dart';

class CsvReader extends Reader {
  const CsvReader(super.config);

  @override
  Stream<MessageEnvelope> read(String source) async* {
    int convoIdCol = 0;
    int fromCol = 0;
    int messageCol = 0;
    bool header = true;

    yield* utf8.decoder
        .bind(File(source).openRead())
        .transform(CsvToListConverter())
        .transform(StreamTransformer.fromHandlers(
            handleData: (List<dynamic> data, sink) {
      // Extract column indexes for configured columns
      // The config could just take col indices instead.
      // This is more human friendly.
      if (header) {
        for (int i = 0; i < data.length; i++) {
          if (data[i] == config['fields']['conversation']) {
            convoIdCol = i;
          } else if (data[i] == config['fields']['from']) {
            fromCol = i;
          } else if (data[i] == config['fields']['message']) {
            messageCol = i;
          }
        }
        header = false;
      } else {
        sink.add(MessageEnvelope(
            Message(data[fromCol], data[messageCol].toString()),
            data[convoIdCol]));
      }
    }));
  }
}
