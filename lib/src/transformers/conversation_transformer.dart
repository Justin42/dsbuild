import 'dart:async';

import '../../dsbuild.dart';
import '../../progress.dart';

/// A [StreamTransformer] that operates on a List\<[Conversation]\>
abstract class ConversationTransformer
    extends StreamTransformerBase<List<Conversation>, List<Conversation>> {
  /// A description of the transformer.
  ///
  /// Example: 'Strip text matching provided patterns'
  String get description => "No description.";

  /// A user supplied description of the transformation step as it relates to the data being processed.
  ///
  /// Example: 'Remove usernames'
  final String stepDescription;

  /// Provided configuration, usually passed from the [DatasetDescriptor]
  final Map config;

  /// Progress
  final ProgressBloc? progress;

  /// Construct a new transformer with the given configuration.
  const ConversationTransformer(this.config,
      {this.stepDescription = '', this.progress});
}

/// A function that takes a [ConversationTransformer.config] Map and returns a [ConversationTransformer]
typedef ConversationTransformerBuilderFn = ConversationTransformer Function(
    Map, ProgressBloc? progress);
