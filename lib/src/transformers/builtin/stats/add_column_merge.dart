import 'dart:collection';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dsbuild/src/conversation.dart';
import 'package:dsbuild/src/transformers/conversation_transformer.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

/// Merge CSV files and perform addition on the given columns for duplicate keys
class StatsAddColMerge extends ConversationTransformer {
  /// Output file
  final File file;

  /// Input file globs
  final List<String> files;

  /// Columns to add
  final IList<int> cols;

  /// Primary key column
  final int pkey;

  /// The minimum count to include in the final output
  final int min;

  /// Append to output file
  final bool append;

  /// Create a new instance
  StatsAddColMerge(super.config, {super.cache})
      : file = File(config['path']),
        files = [for (var glob in config['files']) glob.toString()],
        cols = [
          for (int col in config['cols'] ?? [1]) col
        ].lockUnsafe,
        pkey = config['pkey'] ?? 0,
        min = config['min'] ?? 0,
        append = config['append'] ?? false;

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    yield* stream;

    LinkedHashMap<String, List> indexed = LinkedHashMap();
    CsvToListConverter decoder = CsvToListConverter();
    ListToCsvConverter encoder = ListToCsvConverter();

    // Read and index input data
    for (String pattern in files) {
      Glob glob = Glob(pattern);
      await for (FileSystemEntity entity in glob.list()) {
        if (entity is File) {
          List<List> data = decoder.convert(await entity.readAsString());
          for (List row in data) {
            indexed.update(row[pkey].toString(), (value) {
              // Update with new count
              List newRow = value.toList();
              for (int col in cols) {
                newRow[col] = value[col] +
                    (int.tryParse(row[col]?.toString() ?? '') ?? 0);
              }
              return newRow;
            }, ifAbsent: () {
              List newRow = row.toList();
              for (int col in cols) {
                if (col > newRow.length - 1) continue;
                newRow[col] = int.tryParse(newRow[col]?.toString() ?? '') ?? 0;
              }
              return newRow;
            });
          }
        }
      }
    }

    IOSink ioSink = (await file.create(recursive: true))
        .openWrite(mode: append ? FileMode.append : FileMode.write);
    // Write new data
    ioSink.write(encoder.convert(indexed.values.toList()));

    await ioSink.flush();
    await ioSink.close();
  }
}
