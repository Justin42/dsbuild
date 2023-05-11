class Conversation {
  final List<Message> messages;

  const Conversation({this.messages = const []});

  Map<String, dynamic> toJson() {
    return {
      'conversations': [for(Message message in messages) message.toJson()]
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
  final int conversation;

  bool get isEmpty => _message.value.isEmpty;

  String get from => _message.from;

  String get value => _message.value;

  const MessageEnvelope(this._message, this.conversation);

  MessageEnvelope.empty()
      : _message = Message('', ''),
        conversation = 0;
}

enum Sender { user, other }
