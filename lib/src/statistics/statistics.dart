import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dsbuild/src/math_extensions.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

import '../conversation.dart';
import '../tokenizer/common_tokens.dart' as t;
import '../tokenizer/tokenizer.dart';
import '../tokenizer/vocabulary.dart';
import 'config.dart';
import 'generator.dart';

/// See [MessageStats], [ConversationStats]
sealed class StatisticsData {
  /// Create a new instance
  const StatisticsData();
}

/// Overall statistics for a dataset. Combines [MessageStats] and [ConversationStats]
class Stats extends StatisticsData {
  final StatsConfig _config;
  final StatsGenerator _generator;

  int _messagesTotal = 0;

  /// Configuration for stats.
  StatsConfig get config => _config;

  /// Conversation statistics, mapped by [Conversation.id]
  final LinkedHashMap<int, ConversationStats> _conversations = LinkedHashMap();

  /// Total unique words
  final WordTokenizer tokenizer;

  /// The tokenizer vocabulary.
  Vocabulary<String> get vocabulary => tokenizer.vocab;

  /// Total conversations
  int get conversationsTotal => _conversations.length;

  /// Total number of messages across all conversations.
  int get messagesTotal => _messagesTotal;

  /// The average message count across all conversations.
  double get messagesCountMean => [
        for (ConversationStats conversation in _conversations.values)
          conversation.messagesCount
      ].toList(growable: false).average;

  /// The average length of messages across all conversations.
  double get messagesLenMean => [
        for (ConversationStats conversation in _conversations.values)
          conversation.lenMean
      ].toList(growable: false).average;

  /// The standard deviation of the length of messages across all conversations.
  double get messagesLenStdDev => [
        for (ConversationStats conversation in _conversations.values)
          conversation.lenTotal
      ].toList(growable: false).standardDeviation(population: true);

  /// Total length of all messages.
  int get messagesLenTotal =>
      _conversations.values.fold(0, (total, e) => total + e.lenTotal);

  /// The length of the shortest message across all conversations.
  int get messagesLenMin =>
      _conversations.values.map((e) => e.lenMin).reduce(min);

  /// The length of the longest message across all conversations.
  int get messagesLenMax =>
      _conversations.values.map((e) => e.lenMax).reduce(max);

  /// Create a new instance
  Stats(
      {StatsConfig? config,
      StatsGenerator? generator,
      Vocabulary<String>? vocabulary,
      addCommonTokens = true})
      : _generator = generator ??
            (config != null
                ? BaseStatsGenerator(
                    includeConversationIds: false,
                    includeMessageIds: config.includeMessageIds)
                : const BaseStatsGenerator()),
        _config = config ?? StatsConfig(),
        tokenizer = WordTokenizer(vocabulary ??
            Vocabulary(
                tokens: addCommonTokens
                    ? [
                        ...t.specialTokens,
                        ...t.punctuationTokens,
                        ...t.digitTokens
                      ]
                    : []));

  /// Generate stats for the conversation and add them to the data.
  void push(Conversation conversation) {
    _conversations[conversation.id] =
        _generator.conversationStats(conversation);
    _messagesTotal += conversation.messages.length;
    if (_config.enableVocabulary) {
      for (Message message in conversation.messages) {
        tokenizer.encode(message.value);
      }
    }
  }

  /// See [push]
  void pushAll(List<Conversation> conversations) {
    _conversations.addAll(LinkedHashMap.fromIterable(conversations,
        key: (element) => element.id,
        value: (element) => _generator.conversationStats(element)));
    for (Conversation conversation in conversations) {
      _messagesTotal += conversation.messages.length;
      if (_config.enableVocabulary) {
        for (Message message in conversation.messages) {
          tokenizer.encode(message.value);
        }
      }
    }
  }

  /// Clear all data
  void clear() {
    _messagesTotal = 0;
    _conversations.clear();
    vocabulary.clear();
  }

  /// Add [other] to this. [other] remains unmodified.
  void add(Stats other) {
    throw UnimplementedError();
  }

  /// Convert to json compatible map
  Map<String, dynamic> toMap() => {
        'conversationsTotal': conversationsTotal,
        'messagesTotal': messagesTotal,
        'messagesCountMean': messagesCountMean,
        'messagesLenMean': messagesLenMean,
        'messagesLenStdDev': messagesLenStdDev,
        'messagesLenTotal': messagesLenTotal,
        'messagesLenMin': messagesLenMin,
        'messagesLenMax': messagesLenMax,
        'conversations': <String, dynamic>{
          for (MapEntry<int, ConversationStats> convStats
              in _conversations.entries)
            convStats.key.toString(): convStats.value.toMap()
        },
        'vocabulary': vocabulary.toMap().unlockView,
      };
}

/// Statistics for a single [Message]
@immutable
class MessageStats extends StatisticsData {
  /// Length of the message
  final int length;

  /// Message id
  final int? id;

  /// Create a new instance
  const MessageStats(this.id, this.length);

  /// Convert to json compatible map
  Map<String, dynamic> toMap() => {if (id != null) 'id': id, 'len': length};
}

/// Statistics for a [Conversation]
@immutable
class ConversationStats extends StatisticsData {
  /// Conversation id
  final int? id;

  /// Stats for each message in the conversation
  final IList<MessageStats> messages;

  /// Messages in conversation
  final int messagesCount;

  /// Total length of content of all messages
  final int lenTotal;

  /// Average length of content of all messages
  final double lenMean;

  /// Standard deviation
  final double lenStdDev;

  /// Length of the shortest message
  final int lenMin;

  /// Length of the longest message
  final int lenMax;

  /// Median length of content of all messages
  final num lenMedian;

  /// Range of the minimum and maximum values
  final int lenRange;

  /// Extra stats to be included.
  final Map<String, dynamic> extra;

  /// Create a new instance.
  ConversationStats(
      {this.id,
      required this.messages,
      int? messagesCount,
      required this.lenTotal,
      required this.lenMean,
      required this.lenStdDev,
      required this.lenMin,
      required this.lenMax,
      required this.lenMedian,
      required this.lenRange,
      this.extra = const {}})
      : messagesCount = messagesCount ?? messages.length;

  /// Empty
  ConversationStats.empty()
      : id = 0,
        messages = const IListConst([]),
        messagesCount = 0,
        lenTotal = 0,
        lenMean = 0,
        lenStdDev = 0,
        lenMin = 0,
        lenMax = 0,
        lenMedian = 0,
        lenRange = 0,
        extra = const {};

  /// Convert to json compatible map
  Map<String, dynamic> toMap() => <String, dynamic>{
        if (id != null) 'id': id,
        'messagesCount': messagesCount,
        'lenTotal': lenTotal,
        'lenMean': lenMean,
        'lenStdDev': lenStdDev,
        'lenMin': lenMin,
        'lenMax': lenMax,
        'lenMedian': lenMedian,
        'lenRange': lenRange,
        'messages': messages.map((element) => element.toMap()).toList(),
        ...extra
      };
}
