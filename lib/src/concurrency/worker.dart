import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';

import '../registry.dart';
import 'message.dart';
import 'tasks.dart';

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
