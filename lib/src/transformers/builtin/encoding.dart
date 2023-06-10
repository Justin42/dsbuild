import 'dart:async';
import 'dart:convert';

import '../../conversation.dart';
import '../conversation_transformer.dart';

/// Re-encodes a text using the specified codec. Ensures encoding compatibility.
class Encoding extends ConversationTransformer {
  /// Replacement for invalid characters. Defaults to the UTF-8 replacement character `�`
  final String invalidChar;

  /// Codec as selected by [config]
  ///
  /// Valid values are: `us-ascii`, `utf-8`, `iso-8859-1`
  final Codec<String, List<int>> codec;

  /// Create a new instance
  Encoding(super.config)
      : invalidChar = config['invalid'] ?? r'�',
        codec = switch (config['codec']) {
          'us-ascii' => AsciiCodec(allowInvalid: true),
          'utf-8' => Utf8Codec(allowMalformed: true),
          'iso-8859-1' => Latin1Codec(allowInvalid: true),
          _ => Utf8Codec(allowMalformed: true)
        };

  @override
  String get description =>
      "Effectively strips character codes not present in the specified encoding. Does not affect output encoding.";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (final List<Conversation> data in stream) {
      List<Conversation> conversations = List.from(data, growable: false);
      for (var (int i, Conversation conversation) in data.indexed) {
        List<Message> messages = [];
        for (Message message in conversation.messages) {
          String value = message.value;
          value = codec.decode(value.codeUnits).replaceAll(r'�', invalidChar);
          messages.add(message.copyWith(value: value));
        }
        conversations[i] = conversation.copyWith(messages: messages);
      }
      yield conversations;
    }
  }
}
