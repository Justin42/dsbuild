import 'dart:async';

import 'package:async/async.dart';

/// Buffer and complete incoming Futures, then emit the results.
/// Parallel count is equal to [length].
/// Always waits for the next event in the sequence.
class SynchronizingTransformer<T> extends StreamTransformerBase<Future<T>, T> {
  /// Number of parallel tasks for each worker.
  final int length;

  /// Constructs a new instance
  SynchronizingTransformer(this.length);

  @override
  Stream<T> bind(Stream<Future<T>> stream) async* {
    await for (var next in stream.slices(length)) {
      await for (List<T> results in Future.wait(next).asStream()) {
        for (T result in results) {
          yield result;
        }
      }
    }
  }
}
