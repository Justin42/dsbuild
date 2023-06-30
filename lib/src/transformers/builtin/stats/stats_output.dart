import 'dart:convert';
import 'dart:io';

import 'package:dsbuild/src/tokenizer/vocabulary.dart';

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

  /// Whether to gzip the separate conversations file
  final bool gzipConversations;

  /// Whether to gzip the separate vocabulary file
  final bool gzipVocabulary;

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
        gzipConversations = config['gZipConversations'] ?? true,
        gzipVocabulary = config['gZipVocabulary'] ?? true,
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
        vocabFile != null ? {'vocabulary': result.remove('vocabulary')} : null;
    Map<String, dynamic>? conversations = conversationsFile != null
        ? {'conversations': result.remove('conversations')}
        : null;

    // Setup encoder
    JsonEncoder encoder = JsonEncoder.withIndent(indent);
    GZipCodec? gZipCodecVocabulary;

    // Write output files
    for ((File, Map<String, dynamic>, bool shouldGzip, bool gzipWithVocab) out
        in [
      // Main
      (file, result, false, false),
      // Vocab
      if (vocabFile != null)
        (vocabFile!, vocab ?? <String, dynamic>{}, gzipVocabulary, false),
      // Conversation
      if (conversationsFile != null)
        (
          conversationsFile!,
          conversations ?? <String, dynamic>{},
          gzipConversations,
          false
        )
    ]) {
      var (File outputFile, outputData, bool shouldGzip, bool gzipWithVocab) =
          out;
      await outputFile.create(recursive: true);
      IOSink output = outputFile.openWrite();
      String jsonData = encoder.convert(outputData);
      if (shouldGzip) {
        if (gzipWithVocab) {
          gZipCodecVocabulary = gZipCodecVocabulary ??
              GZipCodec(dictionary: stats.vocabulary.toGzipDictionary());
          output.add(gZipCodecVocabulary.encode(utf8.encode(jsonData)));
        } else {
          output.add(gzip.encode(utf8.encode(jsonData)));
        }
      } else {
        output.write(jsonData);
      }
      await output.flush();
      await output.close();
    }
  }
}
