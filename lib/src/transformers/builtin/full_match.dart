import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../conversation.dart';
import '../postprocessor.dart';
import '../preprocessor.dart';

enum FullMatchAction { drop }

class FullMatch extends Preprocessor {
  final IList<String> patterns;
  final FullMatchAction action;
  final bool caseSensitive;

  FullMatch(super.config)
      : patterns = [
          for (String patterns in config['patterns'])
            config['caseSensitive'] ?? true ? patterns : patterns.toLowerCase()
        ].lock,
        action = FullMatchAction.values.byName(config['action']),
        caseSensitive = config['caseSensitive'] ?? true;

  @override
  String get description {
    switch (action) {
      case FullMatchAction.drop:
        return "Drop messages that exactly match the provided pattern.";
    }
  }

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        switch (action) {
          case FullMatchAction.drop:
            bool skip = false;
            String compareValue =
                caseSensitive ? data.value : data.value.toLowerCase();
            for (String pattern in patterns) {
              switch (action) {
                case FullMatchAction.drop:
                  if (compareValue == pattern) {
                    skip = true;
                    break;
                  }
              }
              if (skip) break;
            }
            if (!skip) {
              sink.add(data);
            }
            break;
        }
      });
}

class FullMatchPost extends Postprocessor {
  final IList<String> patterns;
  final FullMatchAction action;
  final bool caseSensitive;

  FullMatchPost(super.config)
      : patterns = [
          for (String patterns in config['patterns'])
            config['caseSensitive'] ?? true ? patterns : patterns.toLowerCase()
        ].lock,
        action = FullMatchAction.values.byName(config['action']),
        caseSensitive = config['caseSensitive'] ?? true;

  @override
  String get description {
    switch (action) {
      case FullMatchAction.drop:
        return "Drop messages that exactly match the provided pattern.";
    }
  }

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        IList<Message> messages;
        switch (action) {
          case FullMatchAction.drop:
            messages = data.messages.retainWhere((element) {
              String compareValue =
                  caseSensitive ? element.value : element.value.toLowerCase();
              for (String pattern in patterns) {
                if (compareValue == pattern) {
                  return false;
                }
              }
              return true;
            });
            break;
        }
        sink.add(data.copyWith(messages: messages));
      });
}
