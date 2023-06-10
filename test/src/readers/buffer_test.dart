import 'package:dsbuild/src/conversation.dart';
import 'package:dsbuild/src/transformers/buffer.dart';
import 'package:test/test.dart';

final List<MessageEnvelope> testMessages = const [
  MessageEnvelope(Message('Associate', 'Hello User!'), '0'),
  MessageEnvelope(Message('User', 'Hello Associate!'), '0'),
  MessageEnvelope(Message('Human', 'Hello GPT!'), '1'),
  MessageEnvelope(Message('GPT', 'Hello Human!'), '1'),
];

void main() {
  setUp(() async {});

  tearDown(() async {});

  test('ConversationBuffer.flush()', () {
    ConversationBuffer buffer = ConversationBuffer();
    buffer.add(testMessages[0]);
    buffer.add(testMessages[1]);
    Conversation conversation = buffer.flush()!;
    expect(conversation.id, '0'.hashCode,
        reason: conversation == Conversation.empty
            ? 'Empty conversation'
            : 'Invalid conversation Id');
    expect(conversation.meta!['inputId'], '0');
    expect(buffer.total, 1);
    expect(conversation.messages[0].from, 'Associate');
    buffer.clear();
    expect(buffer.total, 0);
  });
}
