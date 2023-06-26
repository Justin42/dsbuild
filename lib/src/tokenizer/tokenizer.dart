import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import 'vocabulary.dart';
import 'vocabulary_codec.dart';

/// A minimal tokenizer for establishing the vocabulary and word counts of a dataset.
///
/// The goals of this implementation:
/// - Wordlevel tokenization to determine total word counts and unique words.
/// - Load *vocabulary* from tokenizer.json
/// - Serialize vocabulary to minimal json
/// Not goals:
/// - Compatibility with any other formats
/// - Vectorization
/// - Any support for downstream inferencing.
/// In general, this tokenizer is only concerned with how the tokenizer vocabulary relates to the dataset that is being processed.
/// The output values of the default implementation are indices into the datasets vocabulary, sorted by their order of appearance.
@immutable
class Tokenizer<T> {
  /// The backing vocabulary.
  final Vocabulary<T> vocab;

  /// Whether or not encoding writes new tokens to the vocabulary. See [VocabularyCodec]
  /// This only affects future calls to [codec]
  final bool train;

  /// The vocabulary index of the default token.
  final int defaultToken;

  /// Get a codec for tokenization.
  VocabularyCodec<T> get codec => VocabularyCodec(vocab, train);

  /// Create a new instance.
  const Tokenizer(this.vocab, [this.train = true, this.defaultToken = 0]);

  /// Clone this instance with new values.
  Tokenizer<T> copyWith({Vocabulary<T>? vocab, bool? train}) =>
      Tokenizer(vocab ?? this.vocab, train ?? this.train);
}

/// Default tokenization for strings.
extension TokenizeString on Tokenizer<String> {
  /// Tokenize the string into a list of indices in the [Vocabulary]
  Stream<int> tokenize(String input) async* {
    Codec<String, int> codec = this.codec;
    List<String> parts = input.split(" ");
    for (var (int i, String part) in parts.indexed) {
      int next = codec.encode(part);
      if (next == -1) {
        next = defaultToken;
      }
      yield next;
      if (i + 1 < parts.length) {
        yield codec.encode(" ");
      }
    }
  }

  /// Decode a list of previously encoded values
  Stream<String> decode(Stream<int> tokenized) {
    return codec.decoder.bind(tokenized);
  }
}
