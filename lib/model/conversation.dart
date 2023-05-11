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
}

class MessageEnvelope {
  final Message _message;
  final String conversationId;

  bool get isEmpty => _message.value.isEmpty;

  String get from => _message.from;

  String get value => _message.value;

  const MessageEnvelope(this._message, this.conversationId);

  MessageEnvelope.empty()
      : _message = Message('', ''),
        conversationId = '';
}

enum Sender { user, other }
