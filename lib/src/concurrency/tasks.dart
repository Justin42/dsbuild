import 'dart:async';

import '../conversation.dart';
import '../descriptor.dart';
import 'message.dart';
import 'worker.dart';

/// Task executed on a worker
abstract class WorkerTask extends WorkerRequest {
  /// Construct a new request of type [RequestType.task]
  const WorkerTask() : super(RequestType.task);

  /// Run the task using the [Worker] context.
  Future<WorkerResponse> run(Worker worker);
}

/// WorkerTask to perform a series of transformations
class TransformTask extends WorkerTask {
  /// Data
  final List<Conversation> batch;

  /// Transformation steps
  final List<StepDescriptor> steps;

  /// A task to perform [steps] on [batch]
  const TransformTask(this.batch, this.steps);

  @override
  Future<WorkerResponse> run(Worker worker) async {
    Stream<List<Conversation>> pipeline = Stream.value(batch);
    for (StepDescriptor step in steps) {
      pipeline = pipeline.transform(
          worker.registry.transformers[step.type]!.call(step.config));
    }

    List<Conversation> transformed = [];
    await for (List<Conversation> conversation in pipeline) {
      transformed.addAll(conversation);
    }
    return TransformResponse(transformed);
  }
}
