import 'dart:math';

import 'package:collection/collection.dart';

/// Functions to sort a list of comparables and return a wrapped version.
extension ToSortedList<E extends num> on Iterable<E> {
  /// Sort the list and wrap it in a [SortedList]
  SortedList<E> toSortedList() => SortedList(toList(growable: false));
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
  /// This mutates the original list and assumes that it has not been previously sorted.
  SortedList(super.base, {final int Function(E a, E b)? compare}) {
    compare != null ? sort(compare) : sort();
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

  /// Standard variation
  double standardDeviation(double mean) {
    if (length == 1) return 0;
    double temp = 0;
    for (var e in this) {
      temp += (e - mean) * (e - mean);
    }
    return sqrt(temp / (length - 1));
  }
}
