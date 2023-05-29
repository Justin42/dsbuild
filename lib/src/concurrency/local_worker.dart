import 'dart:async';
import 'dart:isolate';

import 'package:dsbuild/dsbuild.dart';
import 'package:logging/logging.dart';

import '../registry.dart';
import 'message.dart';
import 'tasks.dart';
import 'worker.dart';

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
