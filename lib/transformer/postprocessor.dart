import 'dart:async';

import '../model/conversation.dart';

abstract class Postprocessor {
  String get description;

  final String stepDescription;
  final Map<String, dynamic> config;

  StreamTransformer<Conversation, Conversation> get transformer;

  const Postprocessor(this.config, {this.stepDescription = ''});
}
