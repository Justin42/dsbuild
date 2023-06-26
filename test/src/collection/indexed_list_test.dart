import 'package:dsbuild/src/collection/indexed_list.dart';
import 'package:test/test.dart';

void main() {
  IndexedList<String> data = IndexedList();

  setUp(() async {});

  tearDown(() async {
    data.clear();
  });

  group("IndexedList", () {
    test('.add()', () {
      data.add("Test");
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
      int idx = data.addIfAbsent("Test");
      expect(idx, 0);
      expect(data[idx], "Test");
    });
  }, tags: const ['collection']);
}
