import 'dart:convert';

import 'package:dsbuild/src/conversation.dart';
import 'package:dsbuild/statistics.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:test/test.dart';

void main() {
  final Stats stats = Stats();

  Conversation conversation = Conversation(0.hashCode,
      messages: [
        Message(0, 'human',
            'This is only a test. Test. 7 Test-8 A. test_sauce27--=')
      ].lock);

  setUp(() async {
    stats.push(conversation);
  });

  tearDown(() async {
    stats.clear();
  });

  group("Statistics", () {
    test('.toMap()', () async {
      //print(stats.toMap()..remove('vocabulary'));
      expect(stats.vocabulary.first, '[UNK]');
      expect(stats.vocabulary.last, 'sauce');
    });

    test('jsonEncode', () async {
      List<Object?> nonEncodableObjects = [];
      jsonEncode(
        stats.toMap(),
        toEncodable: (nonEncodable) {
          nonEncodableObjects.add(nonEncodable);
          return null;
        },
      );
      expect(nonEncodableObjects, [], reason: "Not all objects are encodable");
    });

    test('empty', () async {
      final Stats stats = Stats();
      expect(stats.tokensMin, 0);
      expect(stats.tokensMax, 0);
      expect(stats.tokensTotal, 0);
      expect(stats.tokensMean, 0);
      expect(stats.wordsMin, 0);
      expect(stats.wordsMax, 0);
      expect(stats.messagesCountMean, 0);
      expect(stats.messagesLenMean, 0);
      expect(stats.messagesLenStdDev, 0);
      expect(stats.wordsMean, 0);
    });
  });
}
