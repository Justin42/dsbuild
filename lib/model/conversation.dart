class Conversation {
  final List<Message> messages = const [];

  const Conversation();
}

class Message {
  final String from;
  final String value;

  const Message(this.from, this.value);
}

class MessageEnvelope {
  final Message _message;
  final int conversation;

  bool get isEmpty => _message.value.isEmpty;

  String get from => _message.from;

  String get value => _message.value;

  const MessageEnvelope(this._message, this.conversation);
}

enum Sender { user, other }
