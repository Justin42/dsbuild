import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:dsbuild/dsbuild.dart';
import 'package:logging/logging.dart';

import '../descriptor.dart';
import '../registry.dart';
import 'message.dart';
import 'tasks.dart';

Logger _log = Logger("dsbuild/WorkerPool");

class ExpandingTransformer<T> extends StreamTransformerBase<List<T>, T> {
  const ExpandingTransformer();

  @override
  Stream<T> bind(Stream<List<T>> stream) async* {
    StreamController<T> controller = StreamController(sync: true);
    stream.listen((event) {
      for (T element in event) {
        controller.add(element);
      }
    }, onDone: () async {
      controller.close();
    });
    yield* controller.stream;
  }
}

/// Buffer and complete incoming Futures, then emit the results.
/// Parallel count is equal to [length].
/// Always waits for the next event in the sequence.
class SynchronizingTransformer<T> extends StreamTransformerBase<Future<T>, T> {
  final int length;

  SynchronizingTransformer(this.length);

  @override
  Stream<T> bind(Stream<Future<T>> stream) async* {
    await for (var next in stream.slices(length)) {
      yield* Future.wait(next)
          .asStream()
          .expand((elements) => [for (var element in elements) element]);
    }
  }
}

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
    Isolate workerIsolate =
        await Isolate.spawn(LocalWorker.start, HandshakeMessage(port.sendPort));
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
        .slices(messageBatch)
        .map((data) => run(PreprocessTask(data, steps)).then((value) => switch (
                value) {
              PreprocessResponse result => result.batch,
              _ => throw UnimplementedError()
            }))
        .transform(
            SynchronizingTransformer<List<MessageEnvelope>>(workers.length))
        .transform(ExpandingTransformer());
  }

  Stream<Conversation> postprocess(
      Stream<Conversation> data, List<StepDescriptor> steps) async* {
    yield* data
        .slices(conversationBatch)
        .map((data) => run(PostprocessTask(data, steps)).then((value) =>
            switch (value) {
              PostprocessResponse result => result.batch,
              _ => throw UnimplementedError()
            }))
        .transform(SynchronizingTransformer<List<Conversation>>(workers.length))
        .transform(ExpandingTransformer());
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

class WorkerHandle {
  final StreamQueue<dynamic> rx;
  final SendPort tx;

  const WorkerHandle(this.rx, this.tx);

  void send(WorkerMessage msg) => tx.send(msg);

  Future<void> close() async {
    await rx.cancel();
  }
}

abstract class Worker {
  Registry get registry;

  void process(WorkerTask task);

  void send(WorkerResponse message);
}

class LocalWorker extends Worker {
  final ReceivePort rx;
  final SendPort tx;
  final Registry _registry;

  @override
  Registry get registry => _registry;

  LocalWorker(this.rx, this.tx, {Registry? registry})
      : _registry = registry ??
            Registry(DsBuild.builtinReaders, DsBuild.builtinWriters,
                preprocessors: DsBuild.builtinPreprocessors,
                postprocessors: DsBuild.builtinPostprocessors);

  @override
  Future<WorkerResponse> process(WorkerTask task) {
    return task.run(this);
  }

  @override
  void send(WorkerResponse message) {
    tx.send(message);
  }

  // TODO Allow custom transformers for LocalWorker.
  //void setupRegistry() {}

  static void start(HandshakeMessage handshake) async {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      print(
          '${record.time.toUtc()}/${record.level.name}/${record.loggerName}: ${record.message}');
    });
    final Logger log = Logger("dsbuild/LocalWorker");

    LocalWorker worker = LocalWorker(ReceivePort(), handshake.tx);
    log.finer("Worker started.");
    handshake.tx.send(HandshakeMessage(worker.rx.sendPort));
    await worker.rx.transform(
        StreamTransformer.fromHandlers(handleData: (data, sink) async {
      //WorkerMessage message = data as WorkerMessage;

      //log.info("Received task");
      worker.send(await data.run(worker));
      sink.add(data);
    })).last;
    log.finer("Worker shutting down");
  }
}
