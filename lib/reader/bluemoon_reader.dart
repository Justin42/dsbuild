import 'dart:convert';
import 'dart:io';

import '../model/conversation.dart';
import 'reader.dart';

/// Bluemoon
/// Misc:
/// - Remove conversations between more than two people.
/// - Ensure conversation flow as human -> gpt -> human -> gpt
class BluemoonReader extends Reader {
  const BluemoonReader(super.config);

  @override
  Future<Stream<MessageEnvelope>> read(String source) async {
    List<Map<String, dynamic>> json =
        jsonDecode(await File(source).readAsString());

    return Stream.fromIterable(json).map((event) => MessageEnvelope(
        Message(event['message_username'], event['message']),
        ['thread_href'].hashCode));
  }
}
