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

/// A worker pool for dispatching tasks to local worker threads.
class WorkerPool {
  /// Available workers.
  final List<WorkerHandle> workers;

  /// Managed isolates
  final List<Isolate> localIsolates;

  /// Next worker that a task will be dispatched to.
  int nextWorker = 0;

  /// Construct a new pool.
  WorkerPool()
      : workers = [],
        localIsolates = [];

  /// Start a new local worker.
  Future<WorkerHandle> startLocalWorker() async {
    ReceivePort port = ReceivePort();
    StreamQueue rx = StreamQueue(port);
    Isolate workerIsolate = await Isolate.spawn(
        LocalWorker.start, HandshakeMessage(port.sendPort),
        debugName: "${workers.length}".padLeft(3, '0'));
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

  /// Stop all local workers.
  Future<void> stopLocalWorkers() async {
    await Future.wait<void>([for (var handle in workers) handle.close()]);
    _log.finer("Workers shutdown.");
  }

  /// Dispatch the stream to local workers and transform using the provided [steps]
  Stream<List<Conversation>> transform(
      Stream<List<Conversation>> data, List<StepDescriptor> steps) async* {
    yield* data
        .map((data) =>
            run(TransformTask(data, steps)).then((value) => switch (value) {
                  TransformResponse result => result.batch,
                }))
        .transform(SynchronizingTransformer(workers.length));
  }

  /// Process a [WorkerMessage] on the pool.
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
