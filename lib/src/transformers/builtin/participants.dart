import 'dart:async';
import 'dart:collection';

import 'package:dsbuild/src/transformers/conversation_transformer.dart';

import '../../conversation.dart';

/// Drops conversations according to their participant count.
class Participants extends ConversationTransformer {
  /// Minimum participant count
  final int min;

  /// Maximum participant count
  final int? max;

  // TODO Concatenate consecutive
  // TODO Drop posters with lowest post counts when greater than max
  /// Require alternating participants
  final bool alternating;

  /// Concatenate consecutive messages when [alternating] is true.
  final bool concatenateConsecutive;

  /// Prune the participants messages instead of the conversation when possible
  final bool pruneMessages;

  /// Constructs a new instance
  Participants(super.config)
      : min = config['min'] ?? 0,
        max = config['max'],
        alternating = config['alternating'] ?? false,
        concatenateConsecutive = true,
        pruneMessages = true;

  @override
  String get description =>
      "Filter conversations according to participant count.";

  HashMap<String, int> _getParticipants(Iterable<Message> messages) {
    HashMap<String, int> participants = HashMap();
    for (Message message in messages) {
      participants.update(message.from, (int val) => val + 1,
          ifAbsent: () => 1);
    }
    return participants;
  }

  /// Mutates [participants] and [messages] to remove the participant with the fewest number of messages.
  void _removeLowestParticipant(
      HashMap<String, int> participants, List<Message> messages) {
    if (participants.isEmpty) return;
    MapEntry<String, int>? lowest;
    for (MapEntry<String, int> entry in participants.entries) {
      lowest ??= entry;
      if (entry.value < lowest.value) {
        lowest = entry;
      }
    }
    participants.remove(lowest!.key);
    return messages.retainWhere((element) => element.from != lowest!.key);
  }

  bool _hasConsecutive(Iterable<Message> messages) {
    if (messages.isEmpty) return false;
    String? lastParticipant;
    for (Message message in messages) {
      if (lastParticipant == null) {
        lastParticipant = message.from;
        continue;
      }
      if (message.from == lastParticipant) {
        return true;
      }
      lastParticipant = message.from;
    }
    return false;
  }

  List<Message> _concatenateConsecutive(final Iterable<Message> messages) {
    final List<Message> newMessages = [];
    for (Message message in messages) {
      if (newMessages.isEmpty) {
        newMessages.add(message);
      } else if (message.from == newMessages.last.from) {
        Message lastMessage = newMessages.last;
        newMessages[newMessages.length - 1] = lastMessage.copyWith(
            value: [lastMessage.value, message.value].join("\n"));
      } else {
        newMessages.add(message);
      }
    }
    return newMessages;
  }

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> conversations in stream) {
      List<Conversation> newConversations = [];
      for (Conversation conversation in conversations) {
        HashMap<String, int> participants = HashMap();
        List<Message> messages = conversation.messages.toList();

        /// Remove participants above max or below min with the lowest message counts
        participants = _getParticipants(conversation.messages);
        if (participants.length < min) continue;
        if (max != null && participants.length > max!) {
          if (!pruneMessages) continue;
          do {
            _removeLowestParticipant(participants, messages);
          } while (participants.length > max!);
        }

        /// Concatenate consecutive messages
        if (alternating) {
          if (_hasConsecutive(messages)) {
            if (!concatenateConsecutive) {
              continue;
            } else {
              messages = _concatenateConsecutive(messages);
            }
          }
        }
        newConversations.add(conversation.copyWith(messages: messages));
      }
      yield newConversations;
    }
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
