import '../model/conversation.dart';

abstract class Writer {
  final Map config;

  const Writer(this.config);

  Stream<Conversation> write(
      Stream<Conversation> conversations, String destination);
}
