import 'package:dsbuild/src/tokenizer/tokenizer.dart';
import 'package:dsbuild/src/tokenizer/vocabulary.dart';
import 'package:test/test.dart';

void main() {
  Vocabulary<String> vocabulary = Vocabulary();
  WordTokenizer tokenizer = WordTokenizer(vocabulary);

  setUp(() {
    vocabulary.addAll(["[UNK]", " ", "Test"]);
  });

  tearDown(() {
    vocabulary.clear();
  });

  group('Tokenizer', () {
    test('tokenize', () {
      var result = tokenizer.encode("Test Test Testing").toList();
      expect(vocabulary.length, 4);
      expect(result, [
        [2],
        [2],
        [3]
      ]);
    });

    test('decode', () {
      var encoded = [
        [2],
        [2],
        [3]
      ];
      var result = tokenizer.decode(encoded);
      expect(result, "Test Test [UNK]");
    });
  });
}
