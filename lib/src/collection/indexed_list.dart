import 'dart:collection';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

/// A list indexed by a HashMap. Does not allow duplicates.
///
/// Favors slower operations over reindexing whenever possible.
/// Uses the index for search operations whenever possible.
@internal
class IndexedList<T> extends ListBase<T> {
  /// Backing data
  final List<T> _data = [];

  final LinkedHashMap<T, int> _index = LinkedHashMap();

  @override
  int get length => _data.length;

  @override
  set length(int newLength) {
    if (newLength == _data.length) return;
    if (newLength < _data.length) {
      _index.removeWhere((key, value) => value > newLength - 1);
    }
    _data.length = newLength;
  }

  @override
  T operator [](int index) => _data[index];

  @override
  void add(T element) => addIfAbsent(element);

  @override
  void addAll(Iterable<T> iterable) {
    for (T element in iterable) {
      add(element);
    }
  }

  /// Returns the index of the new or existing element
  int addIfAbsent(T element) => _index.putIfAbsent(element, () {
        _data.add(element);
        return _data.length - 1;
      });

  @override
  bool contains(Object? element) => _index.containsKey(element);

  @override
  int indexOf(Object? element, [int start = 0]) =>
      element == null ? -1 : _index[element] ?? -1;

  @override
  void operator []=(int index, T value) {
    _index.remove(_data[index]);
    _data[index] = value;
    _index[value] = index;
  }

  // TODO Reindex on insertion
  @override
  void insert(int index, T element) {
    throw UnimplementedError();
  }

  // TODO Reindex on removal
  @override
  bool remove(Object? element) {
    throw UnimplementedError();
  }

  @override
  void clear() {
    _data.clear();
    _index.clear();
  }

  /// Return an immutable map with the values of the list as keys and their index as values.
  IMap<T, int> index() {
    return _index.lock;
  }
}
