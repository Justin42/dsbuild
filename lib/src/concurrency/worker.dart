import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:dsbuild/dsbuild.dart';
import 'package:logging/logging.dart';

import '../conversation.dart';
import '../descriptor.dart';
import '../registry.dart';
import 'message.dart';
import 'tasks.dart';

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
    List<MessageEnvelope> pending = [];
    List<Future<List<MessageEnvelope>>> incoming = [];
    return data.transform(
        StreamTransformer.fromHandlers(handleData: (data, sink) async {
      if (pending.length <= preprocessBuffer) {
        pending.add(data);
      } else {
        if (incoming.length < workers.length) {
          incoming.add(
              run(PreprocessTask(pending, steps)).then((WorkerResponse value) {
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
            for (MessageEnvelope next in await response) {
              sink.add(next);
            }
          }
        }
      }
    }, handleDone: (sink) async {
      List<MessageEnvelope> remaining =
          await run(PreprocessTask(pending, steps))
              .then((WorkerResponse value) {
        switch (value) {
          case PreprocessResponse result:
            return result.batch;
          case PostprocessResponse _:
            throw UnsupportedError(
                "Received postprocess response during preprocessing");
        }
      });
      for (MessageEnvelope response in remaining) {
        sink.add(response);
      }
      sink.close();
    }));
  }

  Stream<Conversation> postprocess(
      Stream<Conversation> data, List<StepDescriptor> steps) {
    List<Conversation> pending = [];
    List<Future<List<Conversation>>> incoming = [];
    return data.transform(
        StreamTransformer.fromHandlers(handleData: (data, sink) async {
      if (pending.length <= preprocessBuffer) {
        pending.add(data);
      } else {
        if (incoming.length < workers.length) {
          incoming.add(
              run(PostprocessTask(pending, steps)).then((WorkerResponse value) {
            switch (value) {
              case PreprocessResponse _:
                throw UnsupportedError(
                    "Received preprocess response during postprocessing");
              case PostprocessResponse result:
                return result.batch;
            }
          }));
        } else {
          for (Future<List<Conversation>> response in incoming) {
            for (Conversation next in await response) {
              sink.add(next);
            }
          }
        }
      }
    }, handleDone: (sink) async {
      List<Conversation> remaining = await run(PostprocessTask(pending, steps))
          .then((WorkerResponse value) {
        switch (value) {
          case PreprocessResponse _:
            throw UnsupportedError(
                "Received postprocess response during preprocessing");
          case PostprocessResponse result:
            return result.batch;
        }
      });
      for (Conversation response in remaining) {
        sink.add(response);
      }
      sink.close();
    }));
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
    LocalWorker worker = LocalWorker(ReceivePort(), handshake.tx);
    handshake.tx.send(HandshakeMessage(worker.rx.sendPort));
    await worker.rx
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {}))
        .last;
  }
}
