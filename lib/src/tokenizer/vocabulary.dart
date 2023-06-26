import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

import '../collection/indexed_list.dart';
import 'token.dart';

/// A wrapper around an [IndexedList]<[Token]<[T]>>
@immutable
class Vocabulary<T> {
  final IndexedList<T> _tokens;

  /// Get the token at index.
  T? getToken(int index) => _tokens.getOrNull(index);

  /// The number of elements in the vocabulary.
  int get length => _tokens.length;

  /// Get the index of a token.
  int? getIndex(T token, [bool addIfAbsent = false]) =>
      addIfAbsent ? _tokens.addIfAbsent(token) : _tokens.indexOf(token);

  /// Add [element] to tokens if it does not exist. Returns the index of the new or existing element.
  int add(T element) => _tokens.addIfAbsent(element);

  /// Clear all elements.
  void clear() => _tokens.clear();

  /// Create a new instance.
  Vocabulary({Iterable<T>? tokens}) : _tokens = IndexedList() {
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
