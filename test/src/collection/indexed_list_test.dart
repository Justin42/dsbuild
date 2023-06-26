import 'package:dsbuild/src/collection/indexed_list.dart';
import 'package:dsbuild/src/tokenizer/token.dart';
import 'package:test/test.dart';

void main() {
  IndexedList data = IndexedList();

  setUp(() async {});

  tearDown(() async {
    data.clear();
  });

  group("IndexedList", () {
    test('.add()', () {
      data.add(Token("Test"));
      data.add(Token("Test"));
      data.addIfAbsent(Token("Test"));
      expect(data.length, 1);
      expect(data[0], const Token("Test"));
    });

    test('.indexOf()', () {
      data.add("Test");
      expect(data.indexOf("Test"), 0);
    });

    test('.contains()', () {
      data.add("Test");
      expect(data.contains("Test"), true);
    });

    test('.addIfAbsent()', () {
      int idx = data.addIfAbsent("Test");
      expect(idx, 0);
      expect(data[idx], "Test");
    });
  }, tags: const ['collection']);
}
