import 'package:dsbuild/model/conversation.dart';

import 'reader.dart';

class ShareGptReader extends Reader {
  const ShareGptReader();

  @override
  Stream<MessageEnvelope> process(Stream<Map<String, dynamic>> jsonStream) {
    // TODO: implement process
    throw UnimplementedError();
  }
}
