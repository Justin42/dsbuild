import 'dart:async';

import 'package:logging/logging.dart';

import '../../model/conversation.dart';

final Logger log = Logger("dsbuild");

abstract class Preprocessor {
  String get description;

  final String stepDescription;
  final Map<String, dynamic> config;

  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer;

  const Preprocessor(this.config, {this.stepDescription = ''});
}
