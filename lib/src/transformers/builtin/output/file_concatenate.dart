import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:logging/logging.dart';

import '../../../conversation.dart';
import '../../transformers.dart';

Logger _log = Logger("dsbuild/FileConcatenate");

/// Concatenate lines into a single file
class FileConcatenate extends ConversationTransformer {
  /// Source files
  final List<Glob> globs;

  /// If append is false the file will be overwritten.
  final bool append;

  /// Skip duplicate lines
  final bool ignoreDuplicateLines;

  /// Delete source files
  final bool delete;

  /// Duplicate lines
  final HashSet<String> duplicates;

  /// Output file path
  final String path;

  /// Create a new instance
  FileConcatenate(super.config)
      : globs = [for (var file in config['files'] ?? []) Glob(file.toString())],
        append = config['append'] ?? false,
        ignoreDuplicateLines = config['ignoreDuplicateLines'] ?? false,
        delete = config['delete'] ?? false,
        duplicates = HashSet(),
        path = config['path'];

  @override
  String get description => "Concatenate files.";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> conversations) {
    return conversations
        .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      sink.add(data);
    }, handleDone: (sink) async {
      IOSink output = (await File(path).create(recursive: true))
          .openWrite(mode: append ? FileMode.append : FileMode.write);
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
      _log.info("Concatenated $count files to $path");
    }));
  }
}
