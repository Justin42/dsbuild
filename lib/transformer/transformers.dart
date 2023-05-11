import 'dart:async';

import '../model/conversation.dart';
import 'preprocessor.dart';

class ExactMatch extends Preprocessor {
  const ExactMatch(super.config);

  @override
  String get description =>
      "Prune or strip messages exactly matching the provided text";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data));
}

class PatternMatch extends Preprocessor {
  const PatternMatch(super.config);

  @override
  String get description =>
      "Prune or strip messages matching the provided pattern.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data));
}

class Punctuation extends Preprocessor {
  const Punctuation(super.config);

  @override
  String get description =>
      "Trivial adjustments to whitespace and punctuation.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data));
}

class Trim extends Preprocessor {
  const Trim(super.config);

  @override
  String get description => "Trim whitespace and trailing line endings.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data));
}

class Unicode extends Preprocessor {
  const Unicode(super.config);

  @override
  String get description => "Prune or strip messages containing unicode.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(
          handleData: (data, sink) => sink.add(data));
}
