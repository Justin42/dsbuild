import 'dart:math';

import 'package:collection/collection.dart';

/// Functions to sort a list of comparables and return a wrapped version.
extension ToSortedList<E extends num> on Iterable<E> {
  /// Sort the list and wrap it in a [SortedList]
  SortedList<E> toSortedList() => SortedList(this);
}

/// Collect sum from an iterable
extension Sum<E extends num> on Iterable<E> {
  /// Sum the elements in the list.
  E sum() => fold<E>(0 as E, (E a, E b) => (a + b) as E);
}

/// A wrapper around presorted lists
class SortedList<E extends Comparable<num>> extends UnmodifiableListView<E> {
  /// Sorts the base list and returns this wrapper instance
  ///
  /// This assumes the list has not been previously sorted.
  /// For iterables which copy on [Iterable.toList] this will also copy.
  SortedList(Iterable<E> source, {final int Function(E a, E b)? compare})
      : super(source) {
    List<E> data = source.toList();
    compare != null ? data.sort(compare) : data.sort();
  }

  /// Wrap the base list and assume it has already been sorted.
  SortedList.fromPresorted(super.base);
}

/// Simple math functions on sorted numeric lists
extension SortedNumericList<E extends num> on SortedList<E> {
  /// Calculate the median of a presorted list of integers.
  num median() {
    int middle = length ~/ 2;
    if (length % 2 == 1) {
      return this[middle];
    } else {
      return (this[middle - 1] + this[middle]) / 2.0;
    }
  }

  /// Standard deviation.
  ///
  /// If [population] is true returns population standard deviation `σ`
  /// If [population] is false returns sample standard deviation `s`
  double standardDeviation(double mean, [bool population = false]) {
    if (length == 1) return 0;
    double temp = 0;
    for (var e in this) {
      temp += pow(e - mean, 2);
    }
    return population ? sqrt(temp / length) : sqrt(temp / (length - 1));
  }
}
