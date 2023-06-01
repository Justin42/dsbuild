import 'package:bloc/bloc.dart';

import 'descriptor.dart';

class ProgressState {
  final int messagesTotal;
  final int messagesDropped;
  final int messagesProcessed;

  final int conversationsTotal;
  final int conversationsDropped;
  final int conversationsProcessed;
  final int passesComplete;

  final List<InputDescriptor> inputsProcessed;

  final List<OutputDescriptor> outputsProcessed;

  final bool complete;

  const ProgressState(
      {this.messagesTotal = 0,
      this.messagesDropped = 0,
      this.messagesProcessed = 0,
      this.conversationsTotal = 0,
      this.conversationsDropped = 0,
      this.conversationsProcessed = 0,
      this.passesComplete = 0,
      this.inputsProcessed = const [],
      this.outputsProcessed = const [],
      this.complete = false});

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
          List<InputDescriptor>? inputsProcessed,
          List<OutputDescriptor>? outputsProcessed,
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
          inputsProcessed: inputsProcessed ?? this.inputsProcessed,
          outputsProcessed: outputsProcessed ?? this.outputsProcessed,
          complete: complete ?? this.complete);
}

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  ProgressBloc(super.initialState) {
    on<MessageRead>((event, emit) {
      emit(state.copyWith(messagesTotal: state.messagesTotal + event.count));
    });
    on<MessageProcessed>((event, emit) {
      emit(state.copyWith(
          messagesProcessed: state.messagesProcessed + event.count));
    });
    on<ConversationRead>((event, emit) {
      emit(state.copyWith(conversationsTotal: state.conversationsTotal + 1));
    });
    on<ConversationProcessed>((event, emit) {
      emit(state.copyWith(
          conversationsProcessed: state.conversationsProcessed + event.count));
    });
    on<InputFileProcessed>((event, emit) {
      emit(state.copyWith(
          inputsProcessed: state.inputsProcessed..add(event.descriptor)));
    });
    on<OutputFileProcessed>((event, emit) {
      emit(state.copyWith(
          outputsProcessed: state.outputsProcessed..add(event.descriptor)));
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

sealed class ProgressEvent {
  const ProgressEvent();
}

class MessageRead extends ProgressEvent {
  final int count;

  const MessageRead({this.count = 1});
}

class MessageProcessed extends ProgressEvent {
  final int count;

  const MessageProcessed({this.count = 1});
}

class ConversationRead extends ProgressEvent {
  const ConversationRead();
}

class ConversationProcessed extends ProgressEvent {
  final int count;

  const ConversationProcessed({this.count = 1});
}

class InputFileProcessed extends ProgressEvent {
  final InputDescriptor descriptor;

  const InputFileProcessed(this.descriptor);
}

class OutputFileProcessed extends ProgressEvent {
  final OutputDescriptor descriptor;

  const OutputFileProcessed(this.descriptor);
}

class BuildComplete extends ProgressEvent {
  const BuildComplete();
}

class PassComplete extends ProgressEvent {
  final bool resetCounts;

  const PassComplete({this.resetCounts = false});
}
