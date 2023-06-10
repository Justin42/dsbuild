import 'dart:async';
import 'dart:collection';

import 'package:dsbuild/src/transformers/conversation_transformer.dart';
import 'package:logging/logging.dart';

import '../../conversation.dart';

Logger _log = Logger("dsbuild/transformers");

/// Drops conversations according to their participant count.
class Participants extends ConversationTransformer {
  /// Minimum participant count
  final int min;

  /// Maximum participant count
  final int? max;

  /// Require alternating participants
  final bool alternating;

  int _skipped = 0;

  /// Constructs a new instance
  Participants(super.config)
      : min = config['min'] ?? 0,
        max = config['max'],
        alternating = config['alternating'] ?? false;

  @override
  String get description =>
      "Filter conversations according to participant count.";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> batch in stream) {
      List<Conversation> conversations = [];
      for (Conversation conversation in batch) {
        String? lastParticipant;
        HashSet<String> participants = HashSet();
        bool skip = false;
        for (Message message in conversation.messages) {
          if (lastParticipant == message.from && alternating) {
            skip = true;
            break;
          }
          participants.add(message.from);
          lastParticipant = message.from;
          if (max != null && participants.length > max!) {
            skip = true;
            break;
          }
        }
        if (participants.length < min) skip = true;
        if (!skip) {
          conversations.add(conversation);
        } else {
          _skipped += 1;
        }
      }
      yield conversations;
    }
    _log.finer("${runtimeType.toString()} dropped $_skipped conversations.");
  }
}

/// Rename participants according to the order of their appearance.
class RenameParticipants extends ConversationTransformer {
  /// New participant names.
  List<String> names;

  /// Constructs a new instance
  RenameParticipants(super.config)
      : names = [for (var name in config['names']) name as String];

  @override
  String get description => "Rename participants";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> batch in stream) {
      List<Conversation> conversations = [];
      for (Conversation conversation in batch) {
        Map<String, String> renameMap = {};
        List<Message> messages = conversation.messages.unlock;
        for (var (int i, Message message) in conversation.messages.indexed) {
          if (!renameMap.containsKey(message.from)) {
            if (renameMap.length < names.length) {
              messages[i] = message.copyWith(from: names[renameMap.length]);
              renameMap[message.from] = names[renameMap.length];
            }
          } else {
            messages[i] = message.copyWith(from: renameMap[message.from]);
          }
        }
        conversations.add(conversation.copyWith(messages: messages));
      }
      yield conversations;
    }
  }
}
