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
  Stream<MessageEnvelope> read(String source) async* {
    for (Map<String, dynamic> data
        in jsonDecode(await File(source).readAsString())) {
      yield MessageEnvelope(
          Message(data['message_username'] ?? '', data['message'] ?? ''),
          data['thread_href']);
    }
  }
}
