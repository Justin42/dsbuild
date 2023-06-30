import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

/// A conversation.
@immutable
class Conversation {
  /// Empty conversation
  static Conversation empty = const Conversation(-1);

  /// Identifier
  final int id;

  /// Messages
  final IList<Message> messages;

  /// Metadata
  final IMap<String, dynamic>? meta;

  /// Create a new conversation with the specified ID.
  const Conversation(this.id,
      {this.messages = const IListConst([]), this.meta});

  /// Convert to json-compatible map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': [for (Message message in messages) message.toMap()]
    };
  }

  /// Create a copy of this instance with the supplied values.
  Conversation copyWith(
          {int? id,
          Iterable<Message>? messages,
          IMap<String, dynamic>? meta}) =>
      Conversation(id ?? this.id,
          messages: messages?.toIList() ?? this.messages,
          meta: meta ?? this.meta);
}

/// Helper extension to operate on multiple conversations.
extension Conversations on Iterable<Conversation> {
  /// Count all messages in the conversations.
  int get messageCount {
    int count = 0;
    for (Conversation conversation in this) {
      count += conversation.messages.length;
    }
    return count;
  }
}

/// A message in a conversation.
class Message {
  /// Message sender
  final String from;

  /// Message text value
  final String value;

  /// Message identifier
  final int id;

  /// Create a new message from [from] with [value]
  const Message(this.id, this.from, this.value);

  /// An empty message.
  const Message.empty()
      : from = '',
        value = '',
        id = -1;

  /// Convert to json-compatible map
  Map<String, dynamic> toMap([bool includeId = false]) {
    return {'from': from, 'value': value, if (includeId) 'id': id};
  }

  /// Create a copy of this instance with the supplied values.
  Message copyWith({int? id, String? from, String? value}) =>
      Message(id ?? this.id, from ?? this.from, value ?? this.value);

  @override
  String toString() => "$from: $value";
}

/// An envelope containing a [Message] and a conversation identifier.
@immutable
class MessageEnvelope {
  /// Empty message
  static MessageEnvelope empty = const MessageEnvelope(Message.empty(), '');

  /// Message data
  final Message message;

  /// Conversation identifier
  final String conversationId;

  /// Returns true if the message is empty.
  bool get isEmpty => message.value.isEmpty;

  /// [Message.from]
  String get from => message.from;

  /// [Message.value]
  String get value => message.value;

  /// Create a new instance.
  const MessageEnvelope(this.message, this.conversationId);

  /// Create a copy of this instance with the supplied values.
  MessageEnvelope copyWith({Message? message, String? conversationId}) =>
      MessageEnvelope(
          message ?? this.message, conversationId ?? this.conversationId);

  /// Convenience function for copying with new message content
  MessageEnvelope copyWithValue(String value) =>
      copyWith(message: message.copyWith(value: value));
}
