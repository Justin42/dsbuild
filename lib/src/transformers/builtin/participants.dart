import 'dart:async';
import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:logging/logging.dart';

import '../../conversation.dart';
import '../postprocessor.dart';

Logger _log = Logger("dsbuild/transformers");

class Participants extends Postprocessor {
  final int min;
  final int? max;
  final bool alternating;

  int _skipped = 0;

  Participants(super.config)
      : min = config['min'] ?? 0,
        max = config['max'],
        alternating = config['alternating'] ?? false;

  @override
  String get description =>
      "Filter conversations according to participant count.";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        String? lastParticipant;
        HashSet<String> participants = HashSet();
        bool skip = false;
        for (Message message in data.messages) {
          if (lastParticipant == message.from && alternating) {
            skip = true;
            break;
          }
          participants.add(message.from);
          lastParticipant = message.from;
          if (max != null && participants.length > max!) {
            skip = true;
            break;
          }
        }
        if (participants.length < min) skip = true;
        if (!skip) {
          sink.add(data);
        } else {
          _skipped += 1;
        }
      }, handleDone: (sink) {
        _log.finer(
            "${runtimeType.toString()} dropped $_skipped conversations.");
        sink.close();
      });
}

class RenameParticipants extends Postprocessor {
  List<String> names;

  RenameParticipants(super.config)
      : names = [for (var name in config['names']) name as String];

  @override
  String get description => "Rename participants";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        Map<String, String> renameMap = {};
        List<Message> messages = data.messages.unlock;
        for (int i = 0; i < data.messages.length; i++) {
          Message message = data.messages[i];
          if (!renameMap.containsKey(message.from)) {
            if (renameMap.length < names.length) {
              messages[i] = message.copyWith(from: names[renameMap.length]);
              renameMap[message.from] = names[renameMap.length];
            }
          } else {
            messages[i] = message.copyWith(from: renameMap[message.from]);
          }
        }
        sink.add(data.copyWith(messages: messages.lock));
      });
}
