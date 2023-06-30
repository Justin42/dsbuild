import 'dart:collection';

import '../../statistics.dart';
import '../../tokenizer.dart';
import '../collection/sorted_list.dart';
import '../conversation.dart';
import '../math_extensions.dart';

/// A function that generates [ConversationStats] for a given [Conversation]
typedef ConversationStatsFn = ConversationStats Function(
    Conversation conversation);

/// A function that generates [MessageStats] for a given [Message];
typedef MessageStatsFn = MessageStats Function(Message message);

/// A class that generates stats for messages or conversations.
abstract interface class StatsGenerator {
  /// generate
  ConversationStats conversationStats(Conversation conversation);

  /// Generate stats for a message
  MessageStats messageStats(Message message);
}

/// An implementation of [StatsGenerator] for basic usage.
class BaseStatsGenerator implements StatsGenerator {
  /// Word tokenizer for word counts and vocabulary
  final WordTokenizer? tokenizer;

  /// Create a new instance;
  const BaseStatsGenerator({this.tokenizer});

  @override
  ConversationStats conversationStats(Conversation conversation) {
    LinkedHashMap<int, MessageStats> messages = LinkedHashMap.fromIterable(
        conversation.messages.map(messageStats).toList(),
        key: (element) => element.id,
        value: (element) => element);

    SortedList<int> sortedLengths =
        messages.values.map((e) => e.length).toSortedList();

    int lenTotal = sortedLengths.sum();
    return ConversationStats(conversation.id,
        messages: messages,
        messagesCount: messages.length,
        lenTotal: lenTotal,
        lenMin: sortedLengths.isEmpty ? 0 : sortedLengths.first,
        lenMax: sortedLengths.isEmpty ? 0 : sortedLengths.last,
        lenMean: lenTotal / sortedLengths.length,
        lenMedian: sortedLengths.median,
        lenRange: sortedLengths.last - sortedLengths.first,
        lenStdDev: sortedLengths.standardDeviation(
            mean: lenTotal / sortedLengths.length, population: true));
  }

  @override
  MessageStats messageStats(Message message) {
    return MessageStats(message.id, message.value.length);
  }
}
