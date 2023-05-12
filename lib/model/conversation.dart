class Conversation {
  final int id;
  final List<Message> messages;
  final Map<String, dynamic>? meta;

  const Conversation(this.id, {this.messages = const [], this.meta});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': [for (Message message in messages) message.toJson()]
    };
  }
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
}

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
}

enum Sender { user, other }
