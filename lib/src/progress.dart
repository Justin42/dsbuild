import 'package:bloc/bloc.dart';

import 'descriptor.dart';

class ProgressState {
  final int messagesTotal;
  final int messagesDropped;
  final int messagesProcessed;

  final int conversationsTotal;
  final int conversationsDropped;
  final int conversationsProcessed;

  final int totalInputFiles;
  final List<InputDescriptor> inputsProcessed;

  final int totalOutputFiles;
  final List<OutputDescriptor> outputsProcessed;

  final bool complete;

  const ProgressState(
      {this.totalInputFiles = 0,
      this.totalOutputFiles = 0,
      this.messagesTotal = 0,
      this.messagesDropped = 0,
      this.messagesProcessed = 0,
      this.conversationsTotal = 0,
      this.conversationsDropped = 0,
      this.conversationsProcessed = 0,
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
          List<InputDescriptor>? inputsProcessed,
          List<OutputDescriptor>? outputsProcessed,
          bool? complete}) =>
      ProgressState(
          totalInputFiles: totalInputFiles ?? this.totalInputFiles,
          totalOutputFiles: totalOutputFiles ?? this.totalOutputFiles,
          messagesTotal: messagesTotal ?? this.messagesTotal,
          messagesDropped: messagesDropped ?? this.messagesDropped,
          messagesProcessed: messagesProcessed ?? this.messagesProcessed,
          conversationsTotal: conversationsTotal ?? this.conversationsTotal,
          conversationsDropped:
              conversationsDropped ?? this.conversationsDropped,
          conversationsProcessed:
              conversationsProcessed ?? this.conversationsProcessed,
          inputsProcessed: inputsProcessed ?? this.inputsProcessed,
          outputsProcessed: outputsProcessed ?? this.outputsProcessed,
          complete: complete ?? this.complete);
}

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  ProgressBloc(super.initialState) {
    on<MessageRead>((event, emit) {
      emit(state.copyWith(messagesTotal: state.messagesTotal + 1));
    });
    on<MessageProcessed>((event, emit) {
      emit(state.copyWith(messagesProcessed: state.messagesProcessed + 1));
    });
    on<ConversationRead>((event, emit) {
      emit(state.copyWith(conversationsTotal: state.conversationsTotal + 1));
    });
    on<ConversationProcessed>((event, emit) {
      emit(state.copyWith(
          conversationsProcessed: state.conversationsProcessed + 1));
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
  }
}

sealed class ProgressEvent {
  const ProgressEvent();
}

class MessageRead extends ProgressEvent {
  const MessageRead();
}

class MessageProcessed extends ProgressEvent {
  const MessageProcessed();
}

class ConversationRead extends ProgressEvent {
  const ConversationRead();
}

class ConversationProcessed extends ProgressEvent {
  const ConversationProcessed();
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
