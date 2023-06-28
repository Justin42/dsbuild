import 'dart:convert';
import 'dart:io';

import '../../../conversation.dart';
import '../../../statistics/statistics.dart';
import '../../conversation_transformer.dart';

/// Collect statistics for all conversations.
class StatsOutput extends ConversationTransformer {
  /// Track statistics
  final Stats stats;

  /// Output file
  final File file;

  /// Separate output for vocabulary
  final File? vocabFile;

  /// Separate output for conversations
  final File? conversationsFile;

  /// Json output indent for pretty printing
  final String indent;

  /// Create new instance
  StatsOutput(super.config)
      : stats = Stats(),
        file = File(config['path']),
        vocabFile =
            config['vocabPath'] != null ? File(config['vocabPath']) : null,
        conversationsFile = config['conversationsPath'] != null
            ? File(config['conversationsPath'])
            : null,
        indent = config['indent'] ?? ' ';

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> conversations in stream) {
      stats.pushAll(conversations);
      yield conversations;
    }

    // Prepare data
    Map<String, dynamic> result = stats.toMap();
    Map<String, dynamic>? vocab =
        vocabFile != null ? result.remove('vocabulary') : null;
    Map<String, dynamic>? conversations =
        conversationsFile != null ? result.remove('conversations') : null;

    // Setup encoder
    JsonEncoder encoder = JsonEncoder.withIndent(indent);

    // Write output files
    for ((File, Map<String, dynamic>) out in [
      // Main
      (file, result),
      // Vocab
      if (vocabFile != null) (vocabFile!, vocab ?? <String, dynamic>{}),
      // Conversation
      if (conversationsFile != null)
        (conversationsFile!, conversations ?? <String, dynamic>{})
    ]) {
      var (File outputFile, outputData) = out;
      await outputFile.create(recursive: true);
      IOSink output = outputFile.openWrite();
      output.write(encoder.convert(outputData));
      await output.flush();
      await output.close();
    }
  }
}
