import 'dart:isolate';

import 'package:dsbuild/src/descriptor.dart';

import '../conversation.dart';
import 'worker.dart';

enum RequestType { task }

enum ResponseType { status, preprocess, postprocess }

abstract class WorkerMessage {
  const WorkerMessage();
}

abstract class WorkerRequest extends WorkerMessage {
  final RequestType type;

  const WorkerRequest(this.type);
}

abstract class WorkerTask extends WorkerRequest {
  const WorkerTask() : super(RequestType.task);

  WorkerResponse run(Worker worker);
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

class PreprocessTask extends WorkerTask {
  final List<MessageEnvelope> batch;
  final List<StepDescriptor> steps;

  const PreprocessTask(this.batch, this.steps);

  @override
  WorkerResponse run(Worker worker) {
    // TODO: implement run
    throw UnimplementedError();
  }
}

class PostprocessTask extends WorkerTask {
  final List<Conversation> batch;
  final List<StepDescriptor> steps;

  const PostprocessTask(this.batch, this.steps);

  @override
  WorkerResponse run(Worker worker) {
    // TODO: implement run
    throw UnimplementedError();
  }
}
