import 'package:fast_immutable_collections/fast_immutable_collections.dart';

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
  /// Whether to include message Id's
  final bool includeMessageIds;

  /// Whether to include conversation Id's
  final bool includeConversationIds;

  /// Word tokenizer for word counts and vocabulary
  final WordTokenizer? tokenizer;

  /// Create a new instance;
  const BaseStatsGenerator(
      {this.includeConversationIds = false,
      this.includeMessageIds = true,
      this.tokenizer});

  @override
  ConversationStats conversationStats(Conversation conversation) {
    IList<MessageStats> messages = List.generate(conversation.messages.length,
        (index) => messageStats(conversation.messages[index])).lockUnsafe;
    SortedList<int> sortedLengths =
        messages.map((element) => element.length).toSortedList();

    int lenTotal = sortedLengths.sum();
    return ConversationStats(
        id: includeConversationIds ? conversation.id : null,
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
    return MessageStats(
        includeMessageIds ? message.id : null, message.value.length);
  }
}
