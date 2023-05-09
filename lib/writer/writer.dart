import '../model/conversation.dart';

abstract class Writer {
  Stream<Conversation> write(
      Stream<Conversation> conversation, Uri destination);
}
