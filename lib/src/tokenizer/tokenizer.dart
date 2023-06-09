import 'package:collection/collection.dart';
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
abstract class Tokenizer<S, T> {
  /// The backing vocabulary.
  final Vocabulary<T> vocab;

  /// Whether or not encoding writes new tokens to the vocabulary. See [VocabularyCodec]
  /// This only affects future calls to [codec]
  final bool train;

  /// The vocabulary index of the default token.
  final int defaultToken;

  /// Get a codec for tokenization.
  VocabularyCodec<T> get codec => VocabularyCodec(vocab);

  /// Create a new instance.
  const Tokenizer(this.vocab, {this.train = true, this.defaultToken = 0});

  /// Tokenize input type [S] to [List]<[List]<[T]>> for output token type [T]
  List<List<T>> tokenize(S input);

  /// Tokenize the input and encode into a list of indices in the [Vocabulary]
  List<List<int>> encode(S input);

  /// Decode previously encoded values
  S decode(List<List<int>> encoded);
}

/// A word level tokenizer.
class WordTokenizer extends Tokenizer<String, String> {
  /// Default regex for splitting words into sub tokens
  static final RegExp defaultSplitWord =
      RegExp(r"[a-zA-Z]+|[0-9]|-|!|\.|_|:|=|'");

  static final _log = Logger('dsbuild/WordTokenizer');

  /// Pattern for splitting words. Defaults to [defaultSplitWord]
  final Pattern? splitWord;

  /// Create an instance
  const WordTokenizer(super.vocab,
      {super.train, super.defaultToken, this.splitWord});

  /// Split a word into parts
  List<String> wordParts(String word) {
    return (splitWord ?? defaultSplitWord)
        .allMatches(word)
        .map((e) => word.substring(e.start, e.end))
        .toList();
  }

  /// Split input into words
  List<String> allWords(String input) {
    return input.split(" ");
  }

  /// Tokenize input string into a list of words and punctuation.
  @override
  List<List<String>> tokenize(String input) {
    List<List<String>> output = allWords(input).map(wordParts).toList();
    if (_log.isLoggable(Level.FINEST)) {
      _log.finest('$input => $output');
    }
    if (train) vocab.addAll(output.flattened);
    return output;
  }

  @override
  List<List<int>> encode(String input) {
    return [
      for (List<String> wordParts in tokenize(input))
        wordParts.map(codec.encode).toList(growable: false)
    ];
  }

  @override
  String decode(List<List<int>> encoded) {
    return encoded
        .map((List<int> word) => word.map(codec.decode).join(""))
        .toList()
        .join(" ");
  }

  /// Encode pre-tokenized input.
  List<List<int>> encodeTokenized(List<List<String>> input) {
    return [
      for (List<String> wordParts in input) wordParts.map(codec.encode).toList()
    ];
  }
}
