import 'dart:math';

import 'package:collection/collection.dart';

import 'collection/sorted_list.dart';

/// Collect sum from an iterable
extension NumericIterable<E extends num> on Iterable<E> {
  /// Sum the elements in the list.
  E sum() => fold<E>(0 as E, (E a, E b) => (a + b) as E);

  /// Standard deviation.
  ///
  /// If [population] is true returns population standard deviation `σ`
  /// If [population] is false returns sample standard deviation `s`
  double standardDeviation({double? mean, bool population = false}) {
    if (length == 1) return 0;
    mean = mean ?? average;
    double temp = 0;
    for (var e in this) {
      temp += pow(e - mean, 2);
    }
    return population ? sqrt(temp / length) : sqrt(temp / (length - 1));
  }
}

/// Simple math functions on sorted numeric lists
extension SortedNumericList on SortedList<num> {
  /// Calculate the median of a presorted list of num.
  num get median {
    if (length == 0) {
      throw StateError("Cannot calculate the median of a zero length list");
    }
    int middle = length ~/ 2;
    if (length % 2 == 1) {
      return this[middle];
    } else {
      return (this[middle - 1] + this[middle]) / 2.0;
    }
  }

  /// An alias for [average]
  double get mean => average;
}
