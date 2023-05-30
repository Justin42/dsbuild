import 'dart:async';
import 'dart:convert';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../conversation.dart';
import '../postprocessor.dart';
import '../preprocessor.dart';

class Encoding extends Preprocessor {
  String codecName;
  String invalidChar;
  Codec<String, List<int>>? codec;

  Encoding(super.config)
      : invalidChar = config['invalid'] ?? r'�',
        codecName = config['codec'] {
    codec = switch (codecName) {
      'us-ascii' => AsciiCodec(allowInvalid: true),
      'utf-8' => Utf8Codec(allowMalformed: true),
      'iso-8859-1' => Latin1Codec(allowInvalid: true),
      _ => null
    };
  }

  @override
  String get description =>
      "Effectively strips character codes not present in the specified encoding. Does not affect output encoding.";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.copyWithValue(
            codec!.decode(data.value.codeUnits).replaceAll(r'�', invalidChar)));
      });
}

class EncodingPost extends Postprocessor {
  String codecName;
  String invalidChar;
  Codec<String, List<int>>? codec;

  EncodingPost(super.config)
      : invalidChar = config['invalid'] ?? r'�',
        codecName = config['codec'] {
    codec = switch (codecName) {
      'us-ascii' => AsciiCodec(allowInvalid: true),
      'utf-8' => Utf8Codec(allowMalformed: true),
      'iso-8859-1' => Latin1Codec(allowInvalid: true),
      _ => null
    };
  }

  @override
  String get description =>
      "Effectively strips character codes not present in the specified encoding. Does not affect output encoding.";

  @override
  StreamTransformer<Conversation, Conversation> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.copyWith(
            messages: data.messages.map<Message>((message) {
          String result = codec!.decode(message.value.codeUnits);
          result = result.contains(r'�')
              ? result.replaceAll(r'�', invalidChar)
              : result;
          return message.copyWith(value: result);
        }).toIList()));
      });
}
