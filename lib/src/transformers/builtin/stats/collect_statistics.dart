import 'dart:convert';
import 'dart:io';

import '../../../conversation.dart';
import '../../../statistics/statistics.dart';
import '../../conversation_transformer.dart';

/// Collect statistics for all conversations.
class CollectStatistics extends ConversationTransformer {
  /// Track statistics
  final Stats stats;

  /// Output file
  final File file;

  /// Create new instance
  CollectStatistics(super.config)
      : stats = Stats(),
        file = File(config['file']);

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> conversations in stream) {
      stats.pushAll(conversations);
      yield conversations;
    }
    await file.create(recursive: true);
    IOSink output = file.openWrite();
    output.write(jsonEncode(stats.toMap()));
    await output.flush();
    await output.close();
  }
}
