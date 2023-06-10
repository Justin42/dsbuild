import 'dart:async';
import 'dart:io';

import 'package:dsbuild/src/transformers/conversation_transformer.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../../conversation.dart';

Logger _log = Logger("dsbuild");

/// Raw message output
class RawOutput extends ConversationTransformer {
  /// Output file
  final File file;

  /// Escape line endings
  bool escape;

  /// Create a new instance
  RawOutput(super.config)
      : escape = config['escape'] ?? false,
        file = File(config['path'].toString());

  @override
  Stream<List<Conversation>> bind(
      Stream<List<Conversation>> conversations) async* {
    IOSink ioSink =
        await file.create(recursive: true).then((value) => value.openWrite());
    yield* conversations
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      for (Conversation conversation in data) {
        for (Message message in conversation.messages) {
          if (escape) {
            ioSink.writeln(message.value.replaceAll("\n", r"\n"));
          } else {
            ioSink.writeln(message.value);
          }
        }
      }
      sink.add(data);
    }, handleDone: (sink) async {
      await ioSink.flush();
      ioSink.close();
      sink.close();
      _log.info(
          "Output finalized: $runtimeType ${p.relative(file.path, from: Directory.current.toString())}");
    }));
  }
}
