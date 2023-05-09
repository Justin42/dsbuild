import '../model/conversation.dart';
import 'reader.dart';

/// Bluemoon
/// Misc:
/// - Remove conversations between more than two people.
/// - Ensure conversation flow as human -> gpt -> human -> gpt
class BluemoonReader extends Reader {
  const BluemoonReader(super.config);

  @override
  Stream<MessageEnvelope> process(Stream<Map<String, dynamic>> jsonStream) {
    return jsonStream.map((event) => MessageEnvelope(
        Message(event['message_username'], event['message']),
        ['thread_href'].hashCode));
  }
}
