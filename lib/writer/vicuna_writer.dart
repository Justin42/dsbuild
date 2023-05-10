import 'package:dsbuild/model/conversation.dart';

import 'writer.dart';

class VicunaWriter extends Writer {
  const VicunaWriter(super.config);

  @override
  Stream<Conversation> write(
      Stream<Conversation> conversations, String destination) {
    throw UnimplementedError();
  }
}
