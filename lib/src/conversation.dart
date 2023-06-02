import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

@immutable
class Conversation {
  final int id;
  final IList<Message> messages;
  final IMap<String, dynamic>? meta;

  const Conversation(this.id,
      {this.messages = const IListConst([]), this.meta});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': [for (Message message in messages) message.toJson()]
    };
  }

  Conversation copyWith(
          {int? id, IList<Message>? messages, IMap<String, dynamic>? meta}) =>
      Conversation(id ?? this.id,
          messages: messages ?? this.messages, meta: meta ?? this.meta);
}

class Message {
  final String from;
  final String value;

  const Message(this.from, this.value);

  Map<String, dynamic> toJson() {
    return {'from': from, 'value': value};
  }

  Message copyWith({String? from, String? value}) =>
      Message(from ?? this.from, value ?? this.value);

  Message.empty()
      : from = "",
        value = "";
}

@immutable
class MessageEnvelope {
  final Message message;
  final String conversationId;

  bool get isEmpty => message.value.isEmpty;

  String get from => message.from;

  String get value => message.value;

  const MessageEnvelope(this.message, this.conversationId);

  MessageEnvelope.empty()
      : message = Message('', ''),
        conversationId = '';

  MessageEnvelope copyWith({Message? message, String? conversationId}) =>
      MessageEnvelope(
          message ?? this.message, conversationId ?? this.conversationId);

  /// Convenience function for copying with new message content
  MessageEnvelope copyWithValue(String value) =>
      copyWith(message: message.copyWith(value: value));
}
