import 'dart:async';
import 'dart:isolate';

import 'package:dsbuild/dsbuild.dart';
import 'package:logging/logging.dart';

import '../registry.dart';
import 'message.dart';
import 'tasks.dart';
import 'worker.dart';

/// Channel for interacting with a local worker.
///
/// LocalWorker's are intended to be Dart isolates.
/// This wraps a [ReceivePort], and [SendPort] as well as a [Registry]
class LocalWorker extends Worker {
  final ReceivePort _rx;
  final SendPort _tx;
  final Registry _registry;

  @override
  Registry get registry => _registry;

  /// Construct a new worker with the given [ReceivePort] and [SendPort]
  LocalWorker(this._rx, this._tx, {Registry? registry})
      : _registry =
            registry ?? Registry(transformers: DsBuild.builtinTransformers);

  @override
  Future<WorkerResponse> process(WorkerTask task) {
    return task.run(this);
  }

  @override
  void send(WorkerResponse message) {
    _tx.send(message);
  }

  /// Starts a new local worker that waits for incoming tasks.
  /// A [SendPort] must be provided via the [HandshakeMessage]
  static void start(HandshakeMessage handshake) async {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      print(
          '${record.time.toUtc()}/${record.level.name}/${record.loggerName}: ${record.message}');
    });
    final Logger log = Logger("dsbuild/LocalWorker");

    LocalWorker worker = LocalWorker(ReceivePort(), handshake.tx);
    log.finer("Worker started.");
    handshake.tx.send(HandshakeMessage(worker._rx.sendPort));
    await worker._rx.transform(
        StreamTransformer.fromHandlers(handleData: (data, sink) async {
      //WorkerMessage message = data as WorkerMessage;

      //log.info("Received task");
      worker.send(await data.run(worker));
      sink.add(data);
    })).last;
    log.finer("Worker shutting down");
  }
}
