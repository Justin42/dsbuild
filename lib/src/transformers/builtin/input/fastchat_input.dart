import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dsbuild/progress.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../conversation.dart';
import '../../transformers.dart';

/// Read from FastChat formatted JSON
class FastChatInput extends ConversationTransformer {
  /// Input file path
  final String path;

  /// Whether to preserve conversation Id's
  final bool preserveIds;

  /// Conversation batch size
  final int conversationBatch;

  /// Create new instance
  FastChatInput(super.config, {super.progress})
      : path = config['path'].toString(),
        preserveIds = config['preserveIds'] ?? false,
        conversationBatch = config['conversationBatch'] ?? 100;

  @override
  // TODO: implement description
  String get description => "Read messages from FastChat formatted json.";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    yield* stream;

    List<Conversation> conversations = [];
    List<dynamic> json = jsonDecode(await File(path).readAsString());
    int nextId = 0;
    int messagesRead = 0;

    for (Map<String, dynamic> data in json) {
      IList<Message> messages = [
        for (Map<String, dynamic> message in data['conversations'] ?? [])
          Message(
              (preserveIds && message['id'] != null) ? message['id'] : nextId++,
              message['from'],
              message['value'])
      ].lockUnsafe;
      Conversation conversation = Conversation(data['id'],
          messages: messages, meta: data['meta'] ?? const IMapConst({}));
      conversations.add(conversation);
      messagesRead += messages.length;

      // Yield batch
      if (conversations.length >= conversationBatch) {
        yield conversations;
        progress?.add(ConversationRead(count: conversations.length));
        progress?.add(MessageRead(count: messagesRead));
        messagesRead = 0;
        conversations = [];
      }
    }

    // Yield remaining
    yield conversations;
    progress?.add(ConversationRead(count: conversations.length));
    progress?.add(MessageRead(count: messagesRead));
  }
}
