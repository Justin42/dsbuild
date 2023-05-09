import '../model/conversation.dart';
import 'reader.dart';

class VicunaReader extends Reader {
  const VicunaReader(super.config);

  @override
  Stream<MessageEnvelope> process(Stream<Map<String, dynamic>> jsonStream) {
    throw UnimplementedError();
  }
}
