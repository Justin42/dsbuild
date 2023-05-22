import 'dart:async';

import '../../dsbuild.dart';

abstract class Preprocessor {
  String get description;

  final String stepDescription;
  final Map config;

  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer;

  const Preprocessor(this.config, {this.stepDescription = ''});
}
