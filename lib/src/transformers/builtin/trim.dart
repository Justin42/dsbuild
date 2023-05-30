import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../conversation.dart';
import '../postprocessor.dart';
import '../preprocessor.dart';

class Trim extends Preprocessor {
  const Trim(super.config);

  @override
  String get description => "Trim whitespace and trailing line endings.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        String text = data.message.value.trim();
        if (!identical(text, data.message.value)) {
          sink.add(data.copyWithValue(text));
        } else {
          sink.add(data);
        }
      });
}

class TrimPost extends Postprocessor {
  const TrimPost(super.config);

  @override
  String get description => "Trim whitespace and trailing line endings.";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        List<Message> messages = data.messages.unlockLazy;
        bool modified = false;
        for (int i = 0; i < data.messages.length; i++) {
          Message message = data.messages[i];
          String text = message.value.trim();
          if (!identical(text, message.value)) {
            messages[i] = message.copyWith(value: text);
            modified = true;
          }
        }
        if (modified) {
          sink.add(data.copyWith(messages: messages.lock));
        } else {
          sink.add(data);
        }
      });
}
