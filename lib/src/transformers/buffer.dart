import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../conversation.dart';

/// A buffer for storing incoming messages. Slightly optimized to avoid re-allocations, and hash lookups on presorted data.
class ConversationBuffer {
  /// Total conversations in buffer
  int total = 0;

  /// Current conversation
  final List<MessageEnvelope> current;

  /// Previous conversations
  final HashMap<int, IList<MessageEnvelope>> previous;

  /// Current conversation Id.
  String? get currentConversation => current.getOrNull(0)?.conversationId;

  /// Total active conversations.
  int get activeConversations =>
      previous.length + (current.isNotEmpty ? current.length : 0);

  /// Constructs a new instance
  ConversationBuffer()
      : current = [],
        previous = HashMap();

  /// Flush the current conversation.
  /// If [conversationId] is supplied, a previous conversation will be flushed.
  /// If [update] is false, there will be no hashtable lookup for previous conversations.
  Conversation? flush({String? conversationId, bool update = true}) {
    if (!update) {
      if (current.isEmpty) return null;
      Conversation newConversation = Conversation(
          current[0].conversationId.hashCode,
          messages: current.map((e) => e.message).toIList());
      current.clear();
      return newConversation;
    }
    IList<MessageEnvelope> messages = flip(update: update);
    if (messages.isEmpty) return null;
    total += 1;
    return Conversation(messages[0].conversationId.hashCode,
        messages: messages.map((e) => e.message).toIList(),
        meta: IMap({'inputId': messages[0].conversationId}));
  }

  /// Flush all conversations. Using this while any of the previous conversations are still active will have unexpected results.
  /// Consumers should ensure they do not flush a conversation from the buffer before it is completed.
  /// For pre-sorted data use [flush] at the end of each conversation for best performance.
  List<Conversation> flushAll({String? conversationId, bool update = true}) {
    flip(update: update);
    List<Conversation> all = [
      for (IList<MessageEnvelope> messages
          in previous.values.where((element) => element.isNotEmpty))
        Conversation(messages[0].conversationId.hashCode,
            messages: IList(messages.map((element) => element.message)),
            meta: IMap({'inputId': messages[0].conversationId}))
    ];
    clear();
    total += all.length;
    return all;
  }

  /// Clear the buffer and reset counts.
  void clear() {
    current.clear();
    previous.clear();
    total = 0;
  }

  /// Flip the incoming message buffer into the existing list of messages.
  /// [update] retains previous messages with the same [MessageEnvelope.conversationId]
  IList<MessageEnvelope> flip({bool update = true}) {
    if (current.isEmpty) return const IListConst([]);
    IList<MessageEnvelope> messages = IList(current);
    if (update) {
      IList<MessageEnvelope>? existing =
          previous.remove(current[0].conversationId.hashCode);
      if (existing != null) {
        messages = existing.addAll(messages);
      }
    }
    previous[current[0].conversationId.hashCode] = messages;
    return messages;
  }

  /// Push a conversation into the buffer.
  /// If it does not have the same conversationId as the previous message then the active conversation is stored in a backing HashMap.
  /// If [update] is false then then there will be no check for previously stored conversations before flipping the buffer into the backing HashMap.
  /// For presorted datasets the best performance is achieved with [update] false and using [flush] at the end of each conversation.
  void add(MessageEnvelope envelope, {bool update = true}) {
    if (envelope.conversationId != currentConversation) {
      flip(update: update);
    }
    current.add(envelope);
  }
}
