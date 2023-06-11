import 'dart:isolate';

import '../conversation.dart';
import '../progress.dart';

/// Request type for worker tasks.
enum RequestType {
  /// A request to perform a task.
  task
}

/// Response type for worker responses.
enum ResponseType {
  /// Status response
  status,

  /// Transformation response
  transform
}

/// Message sent to a worker.
abstract class WorkerMessage {
  /// Construct a new message.
  const WorkerMessage();
}

/// Request a worker to perform a task.
abstract class WorkerRequest extends WorkerMessage {
  /// [RequestType] for this message.
  final RequestType type;

  /// Construct a new request of [RequestType]
  const WorkerRequest(this.type);
}

/// Response from a worker.
sealed class WorkerResponse extends WorkerMessage {
  /// [ResponseType] for this message.
  final ResponseType type;

  /// Construct a new response of [ResponseType]
  const WorkerResponse(this.type);
}

/// Handshake providing a [SendPort].
class HandshakeMessage extends WorkerMessage {
  /// [SendPort] that the target should use for outgoing messages.
  final SendPort tx;

  /// Construct a new handshake with the provided [SendPort]
  const HandshakeMessage(this.tx);
}

/// Worker response providing a transformed conversation batch.
class TransformResponse extends WorkerResponse {
  /// Data
  List<Conversation> batch;

  /// New progress after completion. This is merged with overall progress.
  ///
  /// Transformers should **never** report [MessageRead] or [ConversationRead] progress unless they introduce new elements into the stream.
  /// Transformers generally should not report [MessageProcessed] or [ConversationProcessed] but it is up to the receiver how to interpret these counts.
  ProgressState? progress;

  /// Construct a new response containing the provided conversations.
  TransformResponse(this.batch) : super(ResponseType.transform);
}
