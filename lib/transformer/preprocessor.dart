import 'dart:async';

import '../model/conversation.dart';

abstract class Preprocessor {
  String get description;

  final String stepDescription;
  final Map<String, dynamic> config;

  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer;

  const Preprocessor(this.config, {this.stepDescription = ''});
}
