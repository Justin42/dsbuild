import '../model/conversation.dart';
import 'reader.dart';

class VicunaReader extends Reader {
  const VicunaReader();

  @override
  Stream<MessageEnvelope> process(Stream<Map<String, dynamic>> jsonStream) {
    throw UnimplementedError();
  }
}
