import 'package:dsbuild/model/conversation.dart';

import 'writer.dart';

class FastChatWriter extends Writer {
  const FastChatWriter(super.config);

  @override
  Stream<Conversation> write(
      Stream<Conversation> conversations, String destination) {
    throw UnimplementedError();
  }
}
