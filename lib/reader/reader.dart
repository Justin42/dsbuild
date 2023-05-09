import '../model/conversation.dart';

abstract class Reader {
  final Map<String, dynamic> config;

  const Reader(this.config);

  Stream<MessageEnvelope> process(Stream<Map<String, dynamic>> jsonStream);
}
