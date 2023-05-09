import '../model/conversation.dart';

abstract class Writer {
  final Map<String, dynamic> config;

  const Writer(this.config);

  Stream<Conversation> write(Stream<Conversation> conversation,
      Uri destination);
}
