import 'dart:convert';

import 'vocabulary.dart';

/// A codec that converts a type T to it's index in a [Vocabulary]<[T]>
class VocabularyCodec<T> implements Codec<T, int> {
  /// Backing data.
  final Vocabulary<T> vocab;

  /// Value to replace unknown tokens with when encoding if [train] is false.
  static final int unk = 0;

  /// Create a new instance.
  const VocabularyCodec(this.vocab);

  @override
  T decode(int encoded) => decoder.convert(encoded);

  @override
  Converter<int, T> get decoder => VocabularyDecoder(vocab, unk);

  @override
  int encode(T input) => encoder.convert(input);

  @override
  Converter<T, int> get encoder => VocabularyEncoder(vocab, unk);

  @override
  // TODO: implement fuse
  Codec<T, R> fuse<R>(Codec<int, R> other) {
    throw UnimplementedError();
  }

  @override
  // TODO: implement inverted
  Codec<int, T> get inverted => throw UnimplementedError();
}

/// Decode vocabulary indices into [Vocabulary] content type [T].
class VocabularyDecoder<T> extends Converter<int, T> {
  final Vocabulary<T> _vocab;

  /// Index for unknown tokens
  final int unknown;

  /// Create a new instance
  const VocabularyDecoder(Vocabulary<T> vocab, [this.unknown = 0])
      : _vocab = vocab;

  @override
  T convert(int input) {
    return _vocab.getToken(input) ?? _vocab.getToken(unknown)!;
  }
}

/// Encode values of type [T] according to their index within the [Vocabulary]
class VocabularyEncoder<T> extends Converter<T, int> {
  final Vocabulary<T> _vocab;

  /// Unknown token index
  final int unknown;

  /// Create a new instance
  const VocabularyEncoder(Vocabulary<T> vocab, [this.unknown = -1])
      : _vocab = vocab;

  @override
  int convert(T input) {
    return _vocab.getIndex(input) ?? this.unknown;
  }
}
