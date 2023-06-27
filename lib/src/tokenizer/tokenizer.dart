import 'package:logging/logging.dart';
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

/// A word level tokenizer.
class WordTokenizer extends Tokenizer<String> {
  static final _log = Logger('dsbuild/WordTokenizer');

  final RegExp _splitWord = RegExp(r'(\w+|-|!|\.)');

  /// Create an instance
  WordTokenizer(super.vocab);

  /// Split a word into parts
  List<String> wordParts(String word) {
    return _splitWord
        .allMatches(word)
        .map((e) => word.substring(e.start, e.end))
        .toList();
  }

  /// Split input into words
  List<String> allWords(String input) {
    return input.split(" ");
  }

  /// Tokenize input string into a list of words and punctuation.
  List<List<String>> tokenize(String input) {
    List<List<String>> output = allWords(input).map(wordParts).toList();
    if (_log.isLoggable(Level.FINEST)) {
      _log.finest('$input => $output');
    }
    return output;
  }

  /// Encode string into a list of indices in the [Vocabulary]
  List<List<int>> encode(String input) {
    return [
      for (List<String> wordParts in tokenize(input))
        wordParts.map(codec.encode).toList(growable: false)
    ];
  }

  /// Encode pre-tokenized input.
  List<List<int>> encodeTokenized(List<List<String>> input) {
    return [
      for (List<String> wordParts in input) wordParts.map(codec.encode).toList()
    ];
  }

  /// Decode a list of previously encoded values
  String decode(List<List<int>> encoded) {
    return encoded
        .map((List<int> word) => word.map(codec.decode).join(""))
        .toList()
        .join(" ");
  }
}
