import 'dart:async';

import '../model/conversation.dart';

abstract class Postprocessor
    implements StreamTransformer<Conversation, Conversation> {
  @override
  Stream<Conversation> bind(Stream<Conversation> converastionStream);
}
