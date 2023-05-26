import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:logging/logging.dart';

import '../conversation.dart';
import '../descriptor.dart';
import 'message.dart';

Logger _log = Logger("dsbuild/WorkerPool");

class WorkerPool {
  final List<WorkerHandle> workers;
  final List<Isolate> localIsolates;

  final int preprocessBuffer = 100;
  final int postprocessBuffer = 10;

  int nextWorker = 0;

  WorkerPool()
      : workers = const [],
        localIsolates = const [];

  Future<WorkerHandle> startLocalWorker() async {
    _log.info("Starting local worker ${workers.length}...");
    ReceivePort port = ReceivePort();
    StreamQueue<WorkerResponse> rx =
        StreamQueue(port) as StreamQueue<WorkerResponse>;
    Isolate workerIsolate =
        await Isolate.spawn(LocalWorker.start, HandshakeMessage(port.sendPort));
    HandshakeMessage handshake = await rx.next as HandshakeMessage;
    WorkerHandle handle = WorkerHandle(rx, handshake.tx);
    workers.add(handle);
    localIsolates.add(workerIsolate);
    _log.info("Worker ${workers.length} handshake completed.");
    return handle;
  }

  Stream<MessageEnvelope> preprocess(
      Stream<MessageEnvelope> data, List<StepDescriptor> steps) {
    List<Future<List<MessageEnvelope>>> incoming = [];
    return data.transform(
        StreamTransformer.fromHandlers(handleData: (data, sink) async {
      if (incoming.length <= preprocessBuffer) {
        incoming.add(
            run(PreprocessTask([data], steps)).then((WorkerResponse value) {
          switch (value) {
            case PreprocessResponse result:
              return result.batch;
            case PostprocessResponse _:
              throw UnsupportedError(
                  "Received postprocess response during preprocessing");
          }
        }));
      } else {
        for (Future<List<MessageEnvelope>> response in incoming) {
          await response;
        }
      }
    }));
  }

  Stream<Conversation> postprocess(
      Stream<Conversation> data, List<StepDescriptor> steps) {
    return data
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {}));
  }

  Future<WorkerResponse> run(WorkerMessage msg) {
    if (nextWorker >= workers.length) {
      nextWorker = 0;
    }
    WorkerHandle worker = workers[nextWorker];
    worker.send(msg as Message);
    return worker.rx.next;
  }
}

class WorkerHandle {
  final StreamQueue<WorkerResponse> rx;
  final SendPort tx;

  const WorkerHandle(this.rx, this.tx);

  void send(Message msg) => tx.send(msg);
}

abstract class Worker {
  void process(WorkerTask task);

  void send(WorkerResponse message);
}

class LocalWorker extends Worker {
  ReceivePort rx;
  SendPort tx;

  LocalWorker(this.rx, this.tx);

  @override
  WorkerResponse process(WorkerTask task) {
    return task.run(this);
  }

  @override
  void send(WorkerResponse message) {
    tx.send(message);
  }

  static void start(HandshakeMessage handshake) async {
    LocalWorker worker = LocalWorker(ReceivePort(), handshake.tx);
    handshake.tx.send(HandshakeMessage(worker.rx.sendPort));
    await worker.rx
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {}))
        .last;
  }
}
