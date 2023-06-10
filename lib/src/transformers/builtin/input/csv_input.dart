import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

import '../../../conversation.dart';
import '../../buffer.dart';
import '../../conversation_transformer.dart';

/// Read from CSV
class CsvInput extends ConversationTransformer {
  /// Conversation batch size
  final int conversationBatch = 100;

  /// Input file path
  final String path;

  /// Create a new instance.
  CsvInput(super.config) : path = config['path'];

  @override
  // TODO: implement description
  String get description => "Read messages from a CSV file.";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> incoming) async* {
    int convoIdCol = 0;
    int fromCol = 0;
    int messageCol = 0;
    bool header = true;
    ConversationBuffer buffer = ConversationBuffer();
    List<Conversation> batch = [];
    yield* File(path)
        .openRead()
        .transform(StreamTransformer.fromBind(utf8.decoder.bind))
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
            String conversationId = data[convoIdCol].toString();
            bool newConversation = conversationId != buffer.currentConversation;
            MessageEnvelope newMessage = MessageEnvelope(
                Message(data[fromCol].toString(), data[messageCol].toString()),
                conversationId);
            if (newConversation) {
              Conversation? conversation = buffer.flush(update: false);
              if (conversation != null) {
                batch.add(conversation);
              }
            }
            buffer.add(newMessage);
            if (batch.length >= conversationBatch) {
              sink.add(batch);
              batch = [];
            }
          }
        }, handleDone: (sink) {
          batch.addAll(buffer.flushAll());
          sink.add(batch);
          batch = [];
          sink.close();
        }));
  }
}
