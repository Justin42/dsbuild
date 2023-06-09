/// Interact with local and remote workers.
library concurrency;

export 'src/concurrency/local_worker.dart' show LocalWorker;
export 'src/concurrency/pool.dart' show WorkerPool;
export 'src/concurrency/tasks.dart' show WorkerTask, TransformTask;
