import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dsbuild/src/conversation.dart';
import 'package:dsbuild/src/writer.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:logging/logging.dart';

Logger _log = Logger("dsbuild/FileConcatenate");

class FileConcatenate extends Writer {
  List<Glob> globs;
  bool ignoreDuplicateLines;
  bool delete;
  HashSet<String> duplicates;

  FileConcatenate(super.config)
      : globs = [for (var file in config['files'] ?? []) Glob(file.toString())],
        ignoreDuplicateLines = config['ignore_duplicate_lines'] ?? false,
        delete = config['delete'] ?? false,
        duplicates = HashSet();

  @override
  Stream<Conversation> write(
      Stream<Conversation> conversations, String destination) {
    return conversations
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      sink.add(data);
    }, handleDone: (sink) async {
      IOSink output = File(destination).openWrite(mode: FileMode.append);
      int count = 0;
      for (Glob glob in globs) {
        for (FileSystemEntity entity
            in glob.listSync(root: Directory.current.path)) {
          if (entity is File) {
            if (ignoreDuplicateLines) {
              for (String line in await entity.readAsLines()) {
                if (duplicates.add(line)) {
                  output.writeln(line);
                }
              }
            } else {
              await output.addStream(entity.openRead());
            }
            if (delete) {
              entity.deleteSync();
            }
            count += 1;
          }
        }
      }
      await output.flush();
      await output.close();
      sink.close();
      _log.info("Concatenated $count files to $destination");
    }));
  }
}
