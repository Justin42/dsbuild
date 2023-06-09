import 'package:dsbuild/src/collection/indexed_list.dart';
import 'package:test/test.dart';

void main() {
  IndexedList data = IndexedList();

  setUp(() async {});

  tearDown(() async {
    data.clear();
  });

  group("IndexedList", () {
    test('.add()', () {
      data.add("Test");
      data.add("Test");
      data.addIfAbsent("Test");
      expect(data.length, 1);
      expect(data[0], "Test");
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
      int idx = data.addIfAbsent("Test").$1;
      expect(idx, 0);
      expect(data[idx], "Test");
    });
  }, tags: const ['collection']);
}
