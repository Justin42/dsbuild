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

  /// Start time
  final int startTime;

  /// Complete
  final bool complete;

  /// Elapsed time since last reset
  Duration get elapsed => DateTime.now()
      .toUtc()
      .difference(DateTime.fromMillisecondsSinceEpoch(startTime));

  /// Create a new instance
  const ProgressState(
      {this.messagesTotal = 0,
      this.messagesDropped = 0,
      this.messagesProcessed = 0,
      this.conversationsTotal = 0,
      this.conversationsDropped = 0,
      this.conversationsProcessed = 0,
      this.passesComplete = 0,
      this.startTime = 0,
      this.complete = false});

  /// Copy the instance with the provided values.
  ProgressState copyWith(
          {int? messagesTotal,
          int? messagesDropped,
          int? messagesProcessed,
          int? conversationsTotal,
          int? conversationsDropped,
          int? conversationsProcessed,
          int? passesComplete,
          int? startTime,
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
          startTime: startTime ?? this.startTime,
          complete: complete ?? this.complete);

  /// Convert from a json compatible map
  ProgressState.fromJson(Map<String, dynamic> json)
      : messagesTotal = json['messagesTotal'] ?? 0,
        messagesDropped = json['messagesDropped'] ?? 0,
        messagesProcessed = json['messagesProcessed'] ?? 0,
        conversationsTotal = json['conversationTotal'] ?? 0,
        conversationsDropped = json['conversationsDropped'] ?? 0,
        conversationsProcessed = json['conversationsProcessed'] ?? 0,
        passesComplete = json['passesComplete'] ?? 0,
        startTime = json['startTime'] ?? 0,
        complete = json['complete'] ?? false;

  /// Convert to a json compatible map
  Map<String, dynamic> toJson() => {
        'messagesTotal': messagesTotal,
        'messagesDropped': messagesDropped,
        'messagesProcessed': messagesProcessed,
        'conversationsTotal': conversationsTotal,
        'conversationsDropped': conversationsDropped,
        'conversationsProcessed': conversationsProcessed,
        'passesComplete': passesComplete,
        'startTime': startTime,
        'complete': complete
      };
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

    on<ResetTimer>((event, emit) => emit(state.copyWith(
        startTime: DateTime.now().toUtc().millisecondsSinceEpoch)));
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

/// Reset start time for timer
class ResetTimer extends ProgressEvent {
  /// Create a new instance
  const ResetTimer();
}
