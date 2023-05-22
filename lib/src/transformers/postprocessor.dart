import 'dart:async';

import '../conversation.dart';

abstract class Postprocessor {
  String get description;

  final String stepDescription;
  final Map config;

  StreamTransformer<Conversation, Conversation> get transformer;

  const Postprocessor(this.config, {this.stepDescription = ''});
}
