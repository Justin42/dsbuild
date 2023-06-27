import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

import '../conversation.dart';
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
  final Tokenizer<String> tokenizer;

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
      Vocabulary<String>? vocabulary})
      : _generator = generator ??
            (config != null
                ? BaseStatsGenerator(
                    includeConversationIds: false,
                    includeMessageIds: config.includeMessageIds)
                : const BaseStatsGenerator()),
        _config = config ?? StatsConfig(),
        tokenizer = Tokenizer(vocabulary ?? Vocabulary());

  /// Generate stats for the conversation and add them to the data.
  Future<void> push(Conversation conversation) async {
    _conversations[conversation.id] =
        _generator.generateConversationStats(conversation);
    _messagesTotal += conversation.messages.length;
    if (_config.enableVocabulary) {
      for (Message message in conversation.messages) {
        await tokenizer.tokenize(message.value).drain();
      }
    }
  }

  /// See [push]
  Future<void> pushAll(List<Conversation> conversations) async {
    _conversations.addAll(LinkedHashMap.fromIterable(conversations,
        key: (element) => element.id,
        value: (element) => _generator.generateConversationStats(element)));
    for (Conversation conversation in conversations) {
      _messagesTotal += conversation.messages.length;
      if (_config.enableVocabulary) {
        for (Message message in conversation.messages) {
          await tokenizer.tokenize(message.value).drain();
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
        'conversations':
            _conversations.map((key, value) => MapEntry(key, value.toMap())),
        'vocabulary': vocabulary.toMap(),
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
  int get length => messages.length;

  /// Conversation id
  final int? id;

  /// Stats for each message in the conversation
  final IList<MessageStats> messages;

  /// Create a new instance.
  ConversationStats(this.id, Iterable<MessageStats> messages)
      : messages = IList(messages);

  /// Convert to json compatible map
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'messagesTotal': messages.length,
        'messages': messages.toJson((element) => element.toMap())
      };
}
