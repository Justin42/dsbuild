import '../model/conversation.dart';

abstract class Reader {
  final Map config;

  const Reader(this.config);

  Stream<MessageEnvelope> read(String source);
}
