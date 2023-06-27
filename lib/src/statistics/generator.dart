import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../statistics.dart';
import '../conversation.dart';

/// A function that generates [ConversationStats] for a given [Conversation]
typedef ConversationStatsFn = ConversationStats Function(
    Conversation conversation);

/// A function that generates [MessageStats] for a given [Message];
typedef MessageStatsFn = MessageStats Function(Message message);

/// A class that generates stats for messages or conversations.
abstract interface class StatsGenerator {
  /// generate
  ConversationStats generateConversationStats(Conversation conversation);

  /// Generate stats for a message
  MessageStats generateMessageStats(Message message);
}

/// An implementation of [StatsGenerator] for basic usage.
class BaseStatsGenerator implements StatsGenerator {
  /// Whether to include message Id's
  final bool includeMessageIds;

  /// Whether to include conversation Id's
  final bool includeConversationIds;

  /// Create a new instance;
  const BaseStatsGenerator(
      {this.includeConversationIds = false, this.includeMessageIds = true});

  @override
  ConversationStats generateConversationStats(Conversation conversation) =>
      ConversationStats(
          includeConversationIds ? conversation.id : null,
          List.generate(conversation.messages.length,
                  (index) => generateMessageStats(conversation.messages[index]))
              .lockUnsafe);

  @override
  MessageStats generateMessageStats(Message message) =>
      MessageStats(includeMessageIds ? message.id : null, message.value.length);
}
