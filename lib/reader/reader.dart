import '../model/conversation.dart';

abstract class Reader {
  final Map<String, dynamic> config;

  const Reader(this.config);

  Future<Stream<MessageEnvelope>> read(String source);
}
