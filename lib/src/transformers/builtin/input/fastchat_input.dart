import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../../progress.dart';
import '../../../conversation.dart';
import '../../transformers.dart';

/// Read from FastChat formatted JSON
class FastChatInput extends ConversationTransformer {
  /// Input file path
  final String path;

  /// Create new instance
  FastChatInput(super.config, {super.progress})
      : path = config['path'].toString();

  @override
  // TODO: implement description
  String get description => "Read messages from FastChat formatted json.";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    List<dynamic> json = jsonDecode(await File(path).readAsString());

    yield* Stream.fromIterable(json).transform(
        StreamTransformer.fromHandlers(handleData: (conversation, sink) {
      int nextId = 0;
      sink.add([
        Conversation(conversation['id'].hashCode,
            messages: [
              for (dynamic message in conversation['conversations'])
                Message(nextId++, message['from']!, message['value']!)
            ].lock,
            meta: IMap({'inputId': conversation['id']}))
      ]);
      progress?.add(ConversationRead(count: 1));
      progress?.add(MessageRead(count: conversation['conversations'].length));
    }));
  }
}
