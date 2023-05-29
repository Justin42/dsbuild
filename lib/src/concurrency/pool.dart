import 'dart:isolate';

import 'package:async/async.dart';
import 'package:dsbuild/dsbuild.dart';
import 'package:logging/logging.dart';

import '../descriptor.dart';
import 'local_worker.dart';
import 'message.dart';
import 'tasks.dart';
import 'transformers.dart';
import 'worker.dart';

Logger _log = Logger("dsbuild/WorkerPool");

class WorkerPool {
  final List<WorkerHandle> workers;
  final List<Isolate> localIsolates;

  final int messageBatch;
  final int conversationBatch;

  int nextWorker = 0;

  WorkerPool({this.messageBatch = 100, this.conversationBatch = 1})
      : workers = [],
        localIsolates = [];

  Future<WorkerHandle> startLocalWorker() async {
    ReceivePort port = ReceivePort();
    StreamQueue rx = StreamQueue(port);
    Isolate workerIsolate = await Isolate.spawn(
        LocalWorker.start, HandshakeMessage(port.sendPort),
        debugName: "${workers.length}");
    HandshakeMessage handshake = await rx.next as HandshakeMessage;
    WorkerHandle handle = WorkerHandle(rx, handshake.tx);
    workers.add(handle);
    localIsolates.add(workerIsolate);
    _log.finer("Worker ${workers.length} handshake.");
    return handle;
  }

  /// Convenience function. See [startLocalWorker]
  Future<List<WorkerHandle>> startLocalWorkers(int count) async {
    return [for (int i = 0; i < count; i++) await startLocalWorker()];
  }

  Future<void> stopLocalWorkers() async {
    await Future.wait<void>([for (var handle in workers) handle.close()]);
    _log.finer("Workers shutdown.");
  }

  Stream<MessageEnvelope> preprocess(
      Stream<MessageEnvelope> data, List<StepDescriptor> steps) async* {
    yield* data
        .transform(BufferingTransformer<MessageEnvelope>(messageBatch))
        .map((data) =>
            run(PreprocessTask(data, steps)).then((value) => switch (value) {
                  PreprocessResponse result => result.batch,
                  var e => throw UnimplementedError(e.toString())
                }))
        .transform(
            SynchronizingTransformer<List<MessageEnvelope>>(workers.length))
        .transform(const ExpandingTransformer());
  }

  Stream<Conversation> postprocess(
      Stream<Conversation> data, List<StepDescriptor> steps) async* {
    yield* data
        .transform(BufferingTransformer<Conversation>(conversationBatch))
        .map((data) =>
            run(PostprocessTask(data, steps)).then((value) => switch (value) {
                  PostprocessResponse result => result.batch,
                  var e => throw UnimplementedError(e.toString())
                }))
        .transform(SynchronizingTransformer<List<Conversation>>(workers.length))
        .transform(const ExpandingTransformer());
  }

  Future<WorkerResponse> run(WorkerMessage msg) {
    if (nextWorker >= workers.length) {
      nextWorker = 0;
    }
    WorkerHandle worker = workers[nextWorker];
    worker.send(msg);
    nextWorker += 1;
    return worker.rx.next.then((value) => value as WorkerResponse);
  }
}
