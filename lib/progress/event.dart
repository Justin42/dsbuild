part of 'progress.dart';

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
