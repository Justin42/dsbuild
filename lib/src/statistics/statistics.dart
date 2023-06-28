import 'dart:collection';

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
        _generator.generateConversationStats(conversation);
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
        value: (element) => _generator.generateConversationStats(element)));
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
  Map<String, dynamic> toMap() => {if (id != null) 'id': id, 'length': length};
}

/// Statistics for a [Conversation]
@immutable
class ConversationStats extends StatisticsData {
  /// Messages in conversation
  int get messagesTotal => messages.length;

  /// Total length of content of all messages
  int get lengthTotal => messages.sumBy((element) => element.length);

  /// Average length of content of all messages
  double get lengthAverage => lengthTotal / messagesTotal;

  /// Conversation id
  final int? id;

  /// Stats for each message in the conversation
  final IList<MessageStats> messages;

  /// Create a new instance.
  ConversationStats(this.id, Iterable<MessageStats> messages)
      : messages = IList(messages);

  /// Convert to json compatible map
  Map<String, dynamic> toMap() => <String, dynamic>{
        if (id != null) 'id': id,
        'messagesTotal': messagesTotal,
        'lengthTotal': lengthTotal,
        'lengthAverage': lengthAverage,
        'messages': messages.map((element) => element.toMap()).toList()
      };
}
