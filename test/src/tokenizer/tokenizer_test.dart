import 'package:dsbuild/src/tokenizer/tokenizer.dart';
import 'package:dsbuild/src/tokenizer/vocabulary.dart';
import 'package:dsbuild/src/tokenizer/vocabulary_codec.dart';
import 'package:test/test.dart';

void main() {
  Vocabulary<String> vocabulary = Vocabulary();
  Tokenizer<String> tokenizer = Tokenizer(vocabulary, true);

  setUp(() async {
    vocabulary.addAll(["[UNK]", " ", "Test"]);
  });

  tearDown(() async {
    vocabulary.clear();
  });

  group('Tokenizer', () {
    test('tokenize', () async {
      var result = await tokenizer.tokenize("Test Test Testing").toList();
      expect(vocabulary.length, 4);
      expect(result, [2, 1, 2, 1, 3]);
    });

    test('decode', () async {
      VocabularyDecoder<String> decoder =
          tokenizer.codec.decoder as VocabularyDecoder<String>;
      var encoded = [2, 1, 2, 1, 3, 1, 10];
      var result = encoded.map(decoder.convert).toList();
      expect(result.join(""), "Test Test [UNK] [UNK]");
    });
  });
}
