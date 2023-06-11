import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';

import '../../progress.dart';
import '../registry.dart';
import 'message.dart';
import 'tasks.dart';

/// A handle to interact with workers.
class WorkerHandle {
  /// Receive worker responses.
  final StreamQueue<dynamic> rx;

  /// Send worker tasks.
  final SendPort tx;

  /// Construct a new handle.
  const WorkerHandle(this.rx, this.tx);

  /// Send a message to the worker.
  void send(WorkerMessage msg) => tx.send(msg);

  /// Close the receiving channel. A worker with no receiver will be shut down.
  Future<void> close() async {
    await rx.cancel();
  }
}

/// A worker.
abstract class Worker {
  /// Allows tasks to access transformers available to this worker.
  Registry get registry;

  /// Allows tasks to access progress available to this worker.
  ProgressBloc? get progress;

  /// Process an incoming task
  void process(WorkerTask task);

  /// Send an outgoing response.
  void send(WorkerResponse message);
}
