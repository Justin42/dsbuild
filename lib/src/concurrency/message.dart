import 'dart:isolate';

import '../conversation.dart';

enum RequestType { task }

enum ResponseType { status, preprocess, postprocess }

abstract class WorkerMessage {
  const WorkerMessage();
}

abstract class WorkerRequest extends WorkerMessage {
  final RequestType type;

  const WorkerRequest(this.type);
}

sealed class WorkerResponse extends WorkerMessage {
  final ResponseType type;

  const WorkerResponse(this.type);
}

class HandshakeMessage extends WorkerMessage {
  final SendPort tx;

  const HandshakeMessage(this.tx);
}

class PreprocessResponse extends WorkerResponse {
  List<MessageEnvelope> batch;

  PreprocessResponse(this.batch) : super(ResponseType.preprocess);
}

class PostprocessResponse extends WorkerResponse {
  List<Conversation> batch;

  PostprocessResponse(this.batch) : super(ResponseType.postprocess);
}
