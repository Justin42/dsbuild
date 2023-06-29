import 'dart:collection';

/// A wrapper around presorted lists intended to be used with specialized extensions.
///
/// Classes may use this as a guarantee that a list has been previously sorted.
class SortedList<E> extends UnmodifiableListView<E> {
  /// Wrap a previously sorted list.
  SortedList._(super.source);

  /// Wrap the base list and assume it has already been sorted.
  ///
  /// Calling this on an unsorted list is considered API misuse and is guaranteed to cause issues.
  /// This collection operates independently of any sorting functions.
  SortedList.fromPresorted(super.base);

  /// Sort a list and return wrapped
  factory SortedList.fromUnsorted(Iterable<E> source,
          [int Function(E a, E b)? compare]) =>
      compare != null
          ? SortedList._(source.toList(growable: false)..sort(compare))
          : SortedList._(source.toList(growable: false)..sort());
}

/// Convenience function to convert an Iterable<num> to a SortedList<num>
extension ToSortedList<E extends num> on Iterable<E> {
  /// Returns this iterable as a [SortedList] this list remains unmodified. Elements are not copied.
  SortedList<E> toSortedList([bool presorted = false]) => presorted
      ? SortedList.fromPresorted(this)
      : SortedList.fromUnsorted(this);
}
