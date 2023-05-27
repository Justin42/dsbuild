import 'dart:async';

import '../conversation.dart';
import '../descriptor.dart';
import 'message.dart';
import 'worker.dart';

abstract class WorkerTask extends WorkerRequest {
  const WorkerTask() : super(RequestType.task);

  Future<WorkerResponse> run(Worker worker);
}

class PreprocessTask extends WorkerTask {
  final List<MessageEnvelope> batch;
  final List<StepDescriptor> steps;

  const PreprocessTask(this.batch, this.steps);

  @override
  Future<WorkerResponse> run(Worker worker) async {
    Stream<MessageEnvelope> pipeline = Stream.fromIterable(batch);
    for (StepDescriptor step in steps) {
      pipeline = pipeline.transform(worker.registry.preprocessors[step.type]!
          .call(step.config)
          .transformer);
    }
    return PreprocessResponse(await pipeline.toList());
  }
}

class PostprocessTask extends WorkerTask {
  final List<Conversation> batch;
  final List<StepDescriptor> steps;

  const PostprocessTask(this.batch, this.steps);

  @override
  Future<WorkerResponse> run(Worker worker) async {
    Stream<Conversation> pipeline = Stream.fromIterable(batch);
    for (StepDescriptor step in steps) {
      pipeline = pipeline.transform(worker.registry.postprocessors[step.type]!
          .call(step.config)
          .transformer);
    }
    return PostprocessResponse(await pipeline.toList());
  }
}
