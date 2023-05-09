import '../model/conversation.dart';

abstract class Reader {
  const Reader();

  Stream<MessageEnvelope> process(Stream<Map<String, dynamic>> jsonStream);
}
