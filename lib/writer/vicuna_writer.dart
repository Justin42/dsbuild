import 'package:dsbuild/model/conversation.dart';

import 'writer.dart';

class VicunaWriter extends Writer {
  @override
  Stream<Conversation> write(
      Stream<Conversation> conversation, Uri destination) {
    return conversation;
  }
}
