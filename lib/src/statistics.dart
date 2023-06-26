import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

import 'conversation.dart';
import 'tokenizer/vocabulary.dart';

/// See [MessageStats], [ConversationStats]
sealed class StatisticsData {
  /// Create a new instance
  const StatisticsData();
}

/// Statistics for a single [Message]
@immutable
class MessageStats extends StatisticsData {
  /// Length of the message
  final int length;

  /// Create a new instance
  const MessageStats(this.length);
}

/// Statistics for a [Conversation]
@immutable
class ConversationStats extends StatisticsData {
  /// Messages in conversation
  int get length => messages.length;

  /// Stats for each message in the conversation
  final IList<MessageStats> messages;

  /// Create a new instance.
  ConversationStats(Iterable<MessageStats> messages)
      : messages = IList(messages);
}

/// A class that generates stats for messages or conversations.
abstract interface class StatsGenerator {
  /// generate
  ConversationStats generateConversationStats(Conversation conversation);

  /// Generate stats for a message
  MessageStats generateMessageStats(Message message);
}

/// An implementation of [StatsGenerator] for basic usage.
class BaseStatsGenerator implements StatsGenerator {
  /// Create a new instance;
  const BaseStatsGenerator();

  @override
  ConversationStats generateConversationStats(Conversation conversation) {
    // TODO: implement generateConversationStats
    throw UnimplementedError();
  }

  @override
  MessageStats generateMessageStats(Message message) {
    // TODO: implement generateMessageStats
    throw UnimplementedError();
  }
}

/// Configuration for stats tracking
@immutable
class StatsConfig {
  /// Enable vocabulary stats. Significant resource cost for large datasets.
  final bool enableVocabulary = true;

  /// Create a new instance
  const StatsConfig();
}

/// A function that generates [ConversationStats] for a given [Conversation]
typedef ConversationStatsFn = ConversationStats Function(
    Conversation conversation);

/// A function that generates [MessageStats] for a given [Message];
typedef MessageStatsFn = MessageStats Function(Message message);

/// Overall statistics for a dataset. Combines [MessageStats] and [ConversationStats]
class Stats extends StatisticsData {
  final StatsConfig _config;

  final StatsGenerator _generator;

  /// Configuration for stats.
  StatsConfig get config => _config;

  /// Total messages
  int _messagesTotal = 0;

  /// Conversation statistics, mapped by [Conversation.id]
  final LinkedHashMap<int, ConversationStats> _conversations = LinkedHashMap();

  /// Total unique words
  final Vocabulary<String> vocabulary = Vocabulary();

  /// Total conversations
  int get conversationsTotal => _conversations.length;

  /// Total number of messages across all conversations.
  int get messagesTotal => _messagesTotal;

  /// Create a new instance
  Stats({StatsConfig? config, StatsGenerator? generator})
      : _generator = generator ?? const BaseStatsGenerator(),
        _config = config ?? StatsConfig();

  /// Generate stats for the conversation and add them to the data.
  void push(Conversation conversation) {
    // TODO
  }

  /// See [push]
  void pushAll(List<Conversation> conversations) {
    // TODO
  }

  /// Add [other] to this. [other] remains unmodified.
  void add(Stats other) {
    // TODO
  }

  /// Convert to json compatible map
  Map<String, dynamic> toMap() {
    return {
      'conversationsTotal': conversationsTotal,
      'messagesTotal': messagesTotal,
      'conversations': _conversations,
      'vocabulary': vocabulary.toMap(),
    };
  }
}
