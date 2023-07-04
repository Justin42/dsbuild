// ignore_for_file: prefer_collection_literals

import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
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
  int _messagesLenTotal = 0;
  int _wordsTotal = 0;
  int _tokensTotal = 0;

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
  double get messagesCountMean =>
      _conversations.isEmpty ? 0 : _messagesTotal / _conversations.length;

  /// The average length of messages across all conversations.
  double get messagesLenMean =>
      _conversations.isEmpty ? 0 : _messagesLenTotal / _messagesTotal;

  /// The standard deviation of the length of messages across all conversations.
  double get messagesLenStdDev {
    double mean = messagesLenMean;
    if (_conversations.isEmpty) return 0;
    double temp = 0;
    for (ConversationStats conversation in _conversations.values) {
      for (var e
          in conversation.messages.values.map((element) => element.length)) {
        temp += pow(e - mean, 2);
      }
    }
    return sqrt(temp / _messagesTotal);
  }

  /// Total length of all messages.
  int get messagesLenTotal => _messagesLenTotal;

  /// The length of the shortest message across all conversations.
  int get messagesLenMin => _conversations.isEmpty
      ? 0
      : _conversations.values.map((e) => e.lenMin).reduce(min);

  /// The length of the longest message across all conversations.
  int get messagesLenMax => _conversations.isEmpty
      ? 0
      : _conversations.values.map((e) => e.lenMax).reduce(max);

  /// Total words across all conversations
  int get wordsTotal => _wordsTotal;

  /// Mean of word count across all conversations
  double get wordsMean =>
      _conversations.isEmpty ? 0 : _wordsTotal / _messagesTotal;

  /// Standard deviation of the word count of messages across all conversations.
  double get wordsStdDev {
    double mean = wordsMean;
    if (_conversations.values.firstOrNull?.messages.isEmpty ?? true) return 0;
    double temp = 0;
    for (ConversationStats conversation in _conversations.values) {
      for (var e in conversation.messages.values
          .map((element) => element.wordCount ?? 0)) {
        temp += pow(e - mean, 2);
      }
    }
    return sqrt(temp / _messagesTotal);
  }

  /// The minimum word count of any message across all conversations.
  int get wordsMin => _conversations.isEmpty
      ? 0
      : _conversations.values.map((e) => e.wordsMin ?? 0).reduce(min);

  /// The maximum word count of any message across all conversations.
  int get wordsMax => _conversations.isEmpty
      ? 0
      : _conversations.values.map((e) => e.wordsMax ?? 0).reduce(max);

  /// The total token count across all conversations
  int get tokensTotal => _tokensTotal;

  double get tokensMean =>
      _conversations.isEmpty ? 0 : _tokensTotal / _messagesTotal;

  double get tokensStdDev {
    double mean = tokensMean;
    if (_conversations.values.firstOrNull?.messages.isEmpty ?? true) return 0;
    double temp = 0;
    for (ConversationStats conversation in _conversations.values) {
      for (var e in conversation.messages.values
          .map((element) => element.tokenCount ?? 0)) {
        temp += pow(e - mean, 2);
      }
    }
    return sqrt(temp / _messagesTotal);
  }

  /// Minimum token count of any message across all conversations
  int get tokensMin => _conversations.isEmpty
      ? 0
      : _conversations.values.map((e) => e.tokensMin ?? 0).reduce(min);

  /// Maximum token count of any message across all conversations
  int get tokensMax => _conversations.isEmpty
      ? 0
      : _conversations.values.map((e) => e.tokensMax ?? 0).reduce(max);

  /// Create a new instance
  Stats(
      {StatsConfig? config,
      StatsGenerator? generator,
      Vocabulary<String>? vocabulary,
      addCommonTokens = true})
      : _generator = generator ??
            (config != null
                ? BaseStatsGenerator()
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
    ConversationStats stats =
        _generator.conversationStats(conversation, tokenizer: tokenizer);
    _conversations[conversation.id] = stats;
    _messagesTotal += stats.messagesCount;
    _wordsTotal += stats.wordsTotal ?? 0;
    _tokensTotal += stats.tokensTotal ?? 0;
    _messagesLenTotal += stats.lenTotal;

    if (_config.enableVocabulary) {
      for (Message message in conversation.messages) {
        tokenizer.encode(message.value);
      }
    }
  }

  /// See [push]
  void pushAll(List<Conversation> conversations) {
    LinkedHashMap<int, ConversationStats> conversationStats =
        LinkedHashMap<int, ConversationStats>.fromIterable(conversations,
            key: (element) => element.id,
            value: (element) =>
                _generator.conversationStats(element, tokenizer: tokenizer));
    _conversations.addAll(conversationStats);

    for (ConversationStats stats in conversationStats.values) {
      _messagesTotal += stats.messagesCount;
      _wordsTotal += stats.wordsTotal ?? 0;
      _tokensTotal += stats.tokensTotal ?? 0;
      _messagesLenTotal += stats.lenTotal;
    }

    if (_config.enableVocabulary) {
      for (Conversation conversation in conversations) {
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
        'tokensTotal': tokensTotal,
        'tokensMean': tokensMean,
        'tokensStdDev': tokensStdDev,
        'wordsTotal': wordsTotal,
        'wordsMean': wordsMean,
        'wordsStdDev': wordsStdDev,
        'messagesLenMean': messagesLenMean,
        'messagesLenStdDev': messagesLenStdDev,
        'messagesCountMean': messagesCountMean,
        'wordsMin': wordsMin,
        'wordsMax': wordsMax,
        'tokensMin': tokensMin,
        'tokensMax': tokensMax,
        'messagesLenTotal': messagesLenTotal,
        'messagesLenMin': messagesLenMin,
        'messagesLenMax': messagesLenMax,
        'conversations': _conversations
            .map((key, value) => MapEntry(key.toString(), value.toMap())),
        'vocabulary': vocabulary.toMap().unlockView,
      };
}

/// Statistics for a single [Message]
@immutable
class MessageStats extends StatisticsData {
  /// Message id
  final int id;

  /// Length of the message.
  final int length;

  /// A count of the total words in the message.
  final int? wordCount;

  /// A count of the total tokens in the message.
  final int? tokenCount;

  /// Additional data, entries are appended when calling [toMap]
  final Map<String, dynamic> extras;

  /// Create a new instance
  const MessageStats(this.id, this.length,
      {this.wordCount, this.tokenCount, this.extras = const {}});

  /// Convert to json compatible map
  Map<String, dynamic> toMap() => {
        'len': length,
        if (wordCount != null) 'wordCount': wordCount,
        if (tokenCount != null) 'tokenCount': tokenCount,
        ...extras,
      };
}

/// Statistics for a [Conversation]
@immutable
class ConversationStats extends StatisticsData {
  /// Conversation id
  final int id;

  /// Stats for each message in the conversation
  final Map<int, MessageStats> messages;

  /// Messages in conversation
  final int messagesCount;

  /// Words in conversation
  final int? wordsTotal;
  final double? wordsMean;
  final double? wordsStdDev;
  final int? wordsMin;
  final int? wordsMax;
  final num? wordsMedian;
  final int? wordsRange;

  /// Tokens in conversation;
  final int? tokensTotal;
  final double? tokensMean;
  final double? tokensStdDev;
  final int? tokensMin;
  final int? tokensMax;
  final num? tokensMedian;
  final int? tokensRange;

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
  ConversationStats(this.id,
      {required this.messages,
      int? messagesCount,
      this.wordsTotal,
      this.wordsMean,
      this.wordsStdDev,
      this.wordsMin,
      this.wordsMax,
      this.wordsMedian,
      this.wordsRange,
      this.tokensTotal,
      this.tokensMean,
      this.tokensStdDev,
      this.tokensMin,
      this.tokensMax,
      this.tokensMedian,
      this.tokensRange,
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
  const ConversationStats.empty()
      : id = -1,
        messages = const <int, MessageStats>{},
        messagesCount = 0,
        wordsTotal = null,
        wordsMean = null,
        wordsStdDev = null,
        wordsMin = null,
        wordsMax = null,
        wordsMedian = null,
        wordsRange = null,
        tokensTotal = null,
        tokensMean = null,
        tokensStdDev = null,
        tokensMin = null,
        tokensMax = null,
        tokensMedian = null,
        tokensRange = null,
        lenTotal = 0,
        lenMean = 0,
        lenStdDev = 0,
        lenMin = 0,
        lenMax = 0,
        lenMedian = 0,
        lenRange = 0,
        extra = const {};

  /// Convert to json compatible map
  Map<String, dynamic> toMap([bool includeId = false]) => <String, dynamic>{
        if (includeId) 'id': id,
        'messagesCount': messagesCount,
        if (wordsTotal != null) 'wordsTotal': wordsTotal,
        if (wordsMean != null) 'wordsMean': wordsMean,
        if (wordsMin != null) 'wordsMin': wordsMin,
        if (wordsMax != null) 'wordsMax': wordsMax,
        if (wordsMedian != null) 'wordsMedian': wordsMedian,
        if (wordsRange != null) 'wordsRange': wordsRange,
        if (tokensTotal != null) 'tokensTotal': tokensTotal,
        if (tokensMean != null) 'tokensMean': tokensMean,
        if (tokensStdDev != null) 'tokensStdDev': tokensStdDev,
        if (tokensMin != null) 'tokensMin': tokensMin,
        if (tokensMax != null) 'tokensMax': tokensMax,
        if (tokensMedian != null) 'tokensMedian': tokensMedian,
        if (tokensRange != null) 'tokensRange': tokensRange,
        'lenTotal': lenTotal,
        'lenMean': lenMean,
        'lenStdDev': lenStdDev,
        'lenMin': lenMin,
        'lenMax': lenMax,
        'lenMedian': lenMedian,
        'lenRange': lenRange,
        'messages': messages
            .map((key, value) => MapEntry(key.toString(), value.toMap())),
        ...extra
      };
}
