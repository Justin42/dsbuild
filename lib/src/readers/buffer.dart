import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../conversation.dart';

/// A buffer for storing incoming messages. Slightly optimized to avoid re-allocations, and hash lookups on presorted data.
class ConversationBuffer {
  final List<MessageEnvelope> current;
  final HashMap<int, IList<MessageEnvelope>> previous;

  /// Current conversation Id.
  String? get currentConversation => current.getOrNull(0)?.conversationId;

  /// Total active conversations.
  int get activeConversations =>
      previous.length + (current.isNotEmpty ? current.length : 0);

  ConversationBuffer()
      : current = [],
        previous = HashMap();

  /// Flush the current conversation.
  /// If [conversationId] is supplied, a previous conversation will be flushed.
  /// If [update] is false, there will be no hashtable lookup for previous conversations.
  Conversation flush({String? conversationId, bool update = true}) {
    if (conversationId == null && current.isEmpty) {
      return Conversation.empty;
    }
    if (update == false &&
        conversationId != null &&
        conversationId == currentConversation) {
      return Conversation(conversationId.hashCode,
          messages: current.map((e) => e.message).toIList(),
          meta: IMap({'inputId': conversationId}));
    } else {
      if (conversationId != null) {
        flip(update: update);
      }
      IList<MessageEnvelope> messages =
          previous.remove(conversationId) ?? const IListConst([]);
      if (messages.isEmpty) {
        return Conversation.empty;
      } else {
        return Conversation(messages[0].conversationId.hashCode,
            messages: IList(messages.map((element) => element.message)),
            meta: IMap({'inputId': messages[0].conversationId}));
      }
    }
  }

  /// Flush all conversations. Using this while any of the previous conversations are still active will have unexpected results.
  /// Consumers should ensure they do not flush a conversation from the buffer before it is completed.
  /// For pre-sorted data use [flush] at the end of each conversation for best performance.
  List<Conversation> flushAll({String? conversationId, bool update = true}) {
    flip(update: update);
    return [
      for (IList<MessageEnvelope> messages
          in previous.values.where((element) => element.isNotEmpty))
        Conversation(messages[0].conversationId.hashCode,
            messages: IList(messages.map((element) => element.message)),
            meta: IMap({'inputId': messages[0].conversationId}))
    ];
  }

  /// Flip the incoming message buffer into the existing list of messages.
  /// [update] retains previous messages with the same [MessageEnvelope.conversationId]
  void flip({bool update = true}) {
    if (current.isEmpty) return;
    update
        ? previous.update(current[0].conversationId.hashCode,
            (existing) => existing.addAll(current))
        : previous[current[0].conversationId.hashCode] = current.lock;
  }

  /// Push a conversation into the buffer.
  /// If it does not have the same conversationId as the previous message then the active conversation is stored in a backing HashMap.
  /// If [update] is false then then there will be no check for previously stored conversations before flipping the buffer into the backing HashMap.
  /// For presorted datasets the best performance is achieved with [update] false and using [flush] at the end of each conversation.
  void add(MessageEnvelope envelope, {update = true}) {
    if (envelope.conversationId != currentConversation) {
      flip(update: update);
    }
    current.add(envelope);
  }
}
