import 'package:dsbuild/src/conversation.dart';
import 'package:dsbuild/statistics.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:test/test.dart';

void main() {
  final Stats stats = Stats();

  Conversation conversation = Conversation(0.hashCode,
      messages: [
        Message('human', 'This is only a test. Test. 7 Test A. test-sauce')
      ].lock);

  setUp(() async {});

  tearDown(() async {
    stats.clear();
  });

  group("Statistics", () {
    test('.toMap()', () async {
      stats.push(conversation);
      print(stats.toMap());
    });
  });
}
