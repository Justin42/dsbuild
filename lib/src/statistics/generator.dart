import 'dart:collection';

import 'package:collection/collection.dart';

import '../../statistics.dart';
import '../collection/sorted_list.dart';
import '../conversation.dart';
import '../math_extensions.dart';
import '../tokenizer/tokenizer.dart';

/// A function that generates [ConversationStats] for a given [Conversation]
typedef ConversationStatsFn = ConversationStats Function(
    Conversation conversation);

/// A function that generates [MessageStats] for a given [Message];
typedef MessageStatsFn = MessageStats Function(Message message);

/// A class that generates stats for messages or conversations.
abstract interface class StatsGenerator {
  /// generate
  ConversationStats conversationStats(Conversation conversation,
      {Tokenizer<String, String>? tokenizer});

  /// Generate stats for a message
  MessageStats messageStats(Message message,
      {Tokenizer<String, String>? tokenizer});
}

/// An implementation of [StatsGenerator] for basic usage.
class BaseStatsGenerator implements StatsGenerator {
  /// Create a new instance;
  const BaseStatsGenerator();

  @override
  ConversationStats conversationStats(Conversation conversation,
      {Tokenizer<String, String>? tokenizer}) {
    if (tokenizer != null && tokenizer is! WordTokenizer) {
      throw UnimplementedError(
          "Using ${tokenizer.runtimeType} not implemented for this generator. Valid types: ${[
        WordTokenizer
      ]}");
    }
    if (conversation.messages.isEmpty) {
      return ConversationStats.empty();
    }
    LinkedHashMap<int, MessageStats> messages = LinkedHashMap.fromIterable(
        conversation.messages
            .map((e) => messageStats(e, tokenizer: tokenizer))
            .toList(),
        key: (element) => element.id,
        value: (element) => element);

    SortedList<int> sortedLengths =
        messages.values.map((e) => e.length).toSortedList();

    int lenTotal = sortedLengths.sum;
    if (tokenizer != null) {
      SortedList<int> sortedWordCounts =
          messages.values.map((e) => e.wordCount!).toSortedList();

      SortedList<int> sortedTokenCounts =
          messages.values.map((e) => e.tokenCount!).toSortedList();

      int wordsTotal = sortedWordCounts.sum;
      int tokensTotal = sortedTokenCounts.sum;

      return ConversationStats(
        conversation.id,
        messages: messages,
        wordsTotal: wordsTotal,
        wordsMean: wordsTotal / sortedWordCounts.length,
        wordsStdDev: sortedWordCounts.standardDeviation(
            mean: wordsTotal / sortedWordCounts.length, population: true),
        wordsMin: sortedWordCounts.first,
        wordsMax: sortedWordCounts.last,
        wordsMedian: sortedWordCounts.median,
        wordsRange: sortedWordCounts.last - sortedWordCounts.first,
        tokensTotal: tokensTotal,
        tokensMean: tokensTotal / sortedTokenCounts.length,
        tokensStdDev: sortedTokenCounts.standardDeviation(
            mean: tokensTotal / sortedTokenCounts.length, population: true),
        tokensMin: sortedTokenCounts.first,
        tokensMax: sortedTokenCounts.last,
        tokensMedian: sortedTokenCounts.median,
        tokensRange: sortedTokenCounts.last - sortedTokenCounts.first,
        messagesCount: messages.length,
        lenTotal: lenTotal,
        lenMean: lenTotal / sortedLengths.length,
        lenStdDev: sortedLengths.standardDeviation(
            mean: lenTotal / sortedLengths.length, population: true),
        lenMin: sortedLengths.first,
        lenMax: sortedLengths.last,
        lenMedian: sortedLengths.median,
        lenRange: sortedLengths.last - sortedLengths.first,
      );
    } else {
      return ConversationStats(
        conversation.id,
        messages: messages,
        messagesCount: messages.length,
        lenTotal: lenTotal,
        lenMean: lenTotal / sortedLengths.length,
        lenStdDev: sortedLengths.standardDeviation(
            mean: lenTotal / sortedLengths.length, population: true),
        lenMin: sortedLengths.first,
        lenMax: sortedLengths.last,
        lenMedian: sortedLengths.median,
        lenRange: sortedLengths.last - sortedLengths.first,
      );
    }
  }

  @override
  MessageStats messageStats(Message message,
      {Tokenizer<String, String>? tokenizer}) {
    if (tokenizer != null) {
      List<List<String>> tokens = tokenizer.tokenize(message.value);
      return MessageStats(message.id, message.value.length,
          wordCount: tokens.length, tokenCount: tokens.flattened.length);
    } else {
      return MessageStats(message.id, message.value.length);
    }
  }
}
