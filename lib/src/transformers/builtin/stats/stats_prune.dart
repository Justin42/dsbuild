import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dsbuild/src/conversation.dart';
import 'package:logging/logging.dart';

import '../../../../cache.dart';
import '../../../../statistics.dart';
import '../../conversation_transformer.dart';

final Logger _log = Logger("dsbuild/StatsConversationPrune");

/// Prune conversations based on pre-generated statistics data
class StatsConversationPrune extends ConversationTransformer {
  /// Pre-generated statistics. Must include conversation, stats, and vocabulary. Parts may be split or gzipped.
  final String statsPath;

  /// See [statsPath]
  ///
  /// This is required to supply stats to remote workers.
  final String packedStatsPath;

  /// Minimum number of mean words as a ratio of the standard deviation across all conversations.
  ///
  /// This sets the minimum bounds as `min = wordsStdDev - (wordsStdDevRatioMin * wordsStdDev)`
  final double? wordsStdDevRatioMin;

  /// Maximum number of mean words as a ratio of the standard deviation across all conversations.
  ///
  /// This sets the maximum bounds as `max = wordsStdDev + (wordsStdDevRatioMax * wordsStdDev)`
  final double? wordsStdDevRatioMax;

  /// Minimum message length
  ///
  /// This sets the minimum bounds as `min = max(wordsMean - (wordsStdDevRatioMin * wordsStdDev), lenClampMin)
  final int? wordsClampMin;

  /// Maximum message length
  ///
  /// This sets the maximum bounds as `max = min(wordsMean + (wordsStdDevRatioMax * wordsStdDev, lenClampMax)
  final int? wordsClampMax;

  /// Minimum number of messages in conversation
  final int? messagesCountMin;

  /// Maximum number of messages in conversation
  final int? messagesCountMax;

  @override
  PackedDataCache get cache => super.cache!;

  /// Create a new instance
  StatsConversationPrune(super.config, {required super.cache})
      : statsPath = config['statsPath'] ?? '',
        packedStatsPath = config['packedStatsPath'] ?? '',
        wordsStdDevRatioMin = config['wordsStdDevRatioMin'],
        wordsStdDevRatioMax = config['wordsStdDevRatioMax'],
        wordsClampMin = config['wordsClampMin'],
        wordsClampMax = config['wordsClampMax'],
        messagesCountMin = config['messagesCountMin'],
        messagesCountMax = config['messagesCountMax'];

  Future<Stats> _loadStats(String statsPath, {bool fromCache = false}) async {
    if (fromCache) {
      return Stats.fromMap({
        ...jsonDecode(
            String.fromCharCodes(cache['$statsPath/stats.json']!.unpack())),
        // TODO Fix previously gzipped data being sent as raw to local workers when gzipLocalPackedFiles is false
        ...jsonDecode(String.fromCharCodes(
            GzipData(cache['$statsPath/conversations.json.gz']!.data).unpack()))
      });
    } else {
      return Stats.fromMap(jsonDecode(await File(statsPath).readAsString()));
    }
  }

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    final Stats stats;
    if (packedStatsPath.isNotEmpty) {
      stats = await _loadStats(packedStatsPath, fromCache: true);
    } else if (statsPath.isNotEmpty) {
      stats = await _loadStats(statsPath, fromCache: false);
    } else {
      throw ArgumentError(
          "'statsPath' or 'packedStatsPath' must be provided.", "statsPath");
    }

    num minThreshold = wordsStdDevRatioMin != null
        ? stats.wordsStdDev * (wordsStdDevRatioMin ?? 0)
        : 0;
    minThreshold = max(minThreshold, wordsClampMin ?? stats.wordsMin);

    num maxThreshold = wordsStdDevRatioMax != null
        ? stats.wordsStdDev * (wordsStdDevRatioMax ?? stats.wordsMax)
        : stats.wordsMax;
    maxThreshold = min(maxThreshold, wordsClampMax ?? stats.wordsMax);

    await for (List<Conversation> batch in stream) {
      List<Conversation> conversations = [];

      for (Conversation conversation in batch) {
        ConversationStats? convStats = stats.getConversation(conversation.id);
        if (convStats == null) {
          _log.warning(
              "Conversation ID '${conversation.id}' missing from stats.");
          continue;
        }

        // Check for long or short messages
        if (convStats.wordsMin != null && convStats.wordsMin! < minThreshold) {
          continue;
        }
        if (convStats.wordsMax != null && convStats.wordsMax! > maxThreshold) {
          continue;
        }
        // Check for message count
        if (messagesCountMin != null &&
            convStats.messagesCount < messagesCountMin!) {
          continue;
        }
        if (messagesCountMax != null &&
            convStats.messagesCount > messagesCountMax!) {
          continue;
        }

        conversations.add(conversation);
      }

      yield conversations;
    }
  }
}
