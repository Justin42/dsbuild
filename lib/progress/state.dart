part of 'progress.dart';

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
