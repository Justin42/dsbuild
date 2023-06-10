import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import '../../../conversation.dart';
import '../../transformers.dart';

/// Output JSON data formatted for DsBuild
class DsBuildOutput extends ConversationTransformer {
  /// Output file
  File file;

  /// Create a new instance
  DsBuildOutput(super.config)
      : file = File(config['path']
            .toString()
            .replaceAll("%worker%", Isolate.current.debugName ?? '0'));

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    IOSink ioSink =
        await file.create(recursive: true).then((value) => value.openWrite());
    ioSink.writeln("[");

    await for (List<Conversation> batch in stream) {
      for (Conversation conversation in batch) {
        ioSink.write(jsonEncode(conversation.toJson()));
        ioSink.write(',\n');
      }
    }

    ioSink.writeln("]");
    await ioSink.close();
  }
}
