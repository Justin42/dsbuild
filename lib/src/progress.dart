import 'package:bloc/bloc.dart';

/// Progress
class ProgressState {
  /// Total messages
  final int messagesTotal;

  /// Dropped messages
  final int messagesDropped;

  /// Processed messages
  final int messagesProcessed;

  /// Total conversations
  final int conversationsTotal;

  /// Dropped conversations
  final int conversationsDropped;

  /// Processed conversations
  final int conversationsProcessed;

  /// Completed passes
  final int passesComplete;

  /// Complete
  final bool complete;

  /// Create a new instance
  const ProgressState(
      {this.messagesTotal = 0,
      this.messagesDropped = 0,
      this.messagesProcessed = 0,
      this.conversationsTotal = 0,
      this.conversationsDropped = 0,
      this.conversationsProcessed = 0,
      this.passesComplete = 0,
      this.complete = false});

  /// Copy the instance with the provided values.
  ProgressState copyWith(
          {int? totalInputFiles,
          int? totalOutputFiles,
          int? messagesTotal,
          int? messagesDropped,
          int? messagesProcessed,
          int? conversationsTotal,
          int? conversationsDropped,
          int? conversationsProcessed,
          int? passesComplete,
          bool? complete}) =>
      ProgressState(
          messagesTotal: messagesTotal ?? this.messagesTotal,
          messagesDropped: messagesDropped ?? this.messagesDropped,
          messagesProcessed: messagesProcessed ?? this.messagesProcessed,
          conversationsTotal: conversationsTotal ?? this.conversationsTotal,
          conversationsDropped:
              conversationsDropped ?? this.conversationsDropped,
          conversationsProcessed:
              conversationsProcessed ?? this.conversationsProcessed,
          passesComplete: passesComplete ?? this.passesComplete,
          complete: complete ?? this.complete);
}

/// Bloc for [ProgressState]
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  /// Create a new instance and bind listeners.
  ProgressBloc(super.initialState) {
    on<MessageRead>((event, emit) {
      emit(state.copyWith(messagesTotal: state.messagesTotal + event.count));
    });
    on<MessageProcessed>((event, emit) {
      emit(state.copyWith(
          messagesProcessed: state.messagesProcessed + event.count));
    });
    on<ConversationRead>((event, emit) {
      emit(state.copyWith(
          conversationsTotal: state.conversationsTotal + event.count));
    });
    on<ConversationProcessed>((event, emit) {
      emit(state.copyWith(
          conversationsProcessed: state.conversationsProcessed + event.count));
    });
    on<BuildComplete>((event, emit) => emit(state.copyWith(complete: true)));
    on<PassComplete>((event, emit) => emit(state.copyWith(
        passesComplete: state.passesComplete + 1,
        conversationsProcessed: event.resetCounts ? 0 : null,
        conversationsTotal: event.resetCounts ? 0 : null,
        conversationsDropped: event.resetCounts ? 0 : null,
        messagesProcessed: event.resetCounts ? 0 : null,
        messagesTotal: event.resetCounts ? 0 : null,
        messagesDropped: event.resetCounts ? 0 : null)));
  }
}

/// Event for [ProgressBloc]
sealed class ProgressEvent {
  /// Create a new instance
  const ProgressEvent();
}

/// Message read
class MessageRead extends ProgressEvent {
  /// Messages read
  final int count;

  /// Create a new instance
  const MessageRead({this.count = 1});
}

/// Message processed
class MessageProcessed extends ProgressEvent {
  /// Messages processed
  final int count;

  /// Create a new instance
  const MessageProcessed({this.count = 1});
}

/// Conversation read
class ConversationRead extends ProgressEvent {
  /// Conversations read
  final int count;

  /// Create a new instance
  const ConversationRead({this.count = 1});
}

/// Conversation processed
class ConversationProcessed extends ProgressEvent {
  /// Conversations processed
  final int count;

  /// Create a new instance
  const ConversationProcessed({this.count = 1});
}

/// Build completed
class BuildComplete extends ProgressEvent {
  /// Create a new instance
  const BuildComplete();
}

/// Pass completed
class PassComplete extends ProgressEvent {
  /// Reset progress counts
  final bool resetCounts;

  /// Create a new instance
  const PassComplete({this.resetCounts = false});
}
