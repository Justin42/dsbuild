import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

import '../collection/indexed_list.dart';

/// A wrapper around an [IndexedList]<[T]>
@immutable
class Vocabulary<T> {
  final IndexedList<T> _tokens;

  /// The initial length of the vocabulary at the time of creation.
  final int initialLength;

  /// Get the token at index.
  T? getToken(int index) => _tokens.getOrNull(index);

  /// The number of elements in the vocabulary.
  int get length => _tokens.length;

  /// The first element
  T get first => _tokens.first;

  /// The last element
  T get last => _tokens.last;

  /// Get the last [count] elements
  List<T> tail(int count) =>
      _tokens.getRange(_tokens.length - count, _tokens.length).toList();

  /// Get the index of a token.
  int? getIndex(T token, [bool addIfAbsent = false]) =>
      addIfAbsent ? _tokens.addIfAbsent(token).$1 : _tokens.indexOf(token);

  /// Add [element] to tokens if it does not exist. Returns the index of the new or existing element.
  int add(T element) => _tokens.addIfAbsent(element).$1;

  /// Adds all elements from [other] and returns the number of new elements.
  ///
  /// The new elements can be retrieved by passing the return value to [tail]
  int addAllFrom(Vocabulary<T> other) {
    int startLen = _tokens.length;
    _tokens.addAll(other._tokens);
    return _tokens.length - startLen;
  }

  /// Clear all elements.
  void clear() => _tokens.clear();

  /// Create a new instance.
  Vocabulary({Iterable<T>? tokens})
      : _tokens = IndexedList(),
        initialLength = tokens?.length ?? 0 {
    if (tokens != null) _tokens.addAll(tokens);
  }

  /// See [IndexedList.addAll]
  void addAll(Iterable<T> elements) {
    _tokens.addAll(elements);
  }

  @override
  String toString() => _tokens.toString();

  /// Returns an immutable copy of the vocabulary mapped in the form of [IMap]<[T],[int]> where the value is the indices in the vocabulary.
  IMap<T, int> toMap() => _tokens.index();
}

/// Functions to aid in the use of the vocabulary as a compression dictionary.
extension AsCompressionDictionary on Vocabulary<String> {
  /// Returns a list of all words, in reverse order, encoded as utf8, flattened.
  List<int> toGzipDictionary() =>
      _tokens.reversed.map(utf8.encode).flattened.toList(growable: false);
}
