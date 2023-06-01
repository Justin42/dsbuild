import 'dart:async';
import 'dart:collection';

import 'package:async/async.dart';

class BufferingTransformer<T> extends StreamTransformerBase<T, List<T>> {
  final ListQueue<T> buffer;
  final int length;

  BufferingTransformer(this.length) : buffer = ListQueue(length);

  @override
  Stream<List<T>> bind(Stream<T> stream) async* {
    StreamController<List<T>> controller = StreamController(sync: true);
    stream.listen((event) {
      if (buffer.length >= length) {
        controller.add(buffer.toList(growable: false));
        buffer.clear();
      }
      buffer.add(event);
    }, onDone: () async {
      controller.add(buffer.toList(growable: false));
      buffer.clear();
      await controller.close();
    });
    yield* controller.stream;
  }
}

class ExpandingTransformer<T> extends StreamTransformerBase<List<T>, T> {
  const ExpandingTransformer();

  @override
  Stream<T> bind(Stream<List<T>> stream) async* {
    StreamController<T> controller = StreamController(sync: true);
    stream.listen((List<T> event) {
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
      yield* Future.wait(next).asStream().transform(ExpandingTransformer<T>());
    }
  }
}
