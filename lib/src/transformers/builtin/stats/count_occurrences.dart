import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:csv/csv.dart';
import 'package:dsbuild/src/conversation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:logging/logging.dart';

import '../../../packed_data.dart';
import '../../transformers.dart';

final Logger _log = Logger('dsbuild/StatsCountOccurrences');

/// Count occurrences of patterns in the dataset. Reads patterns from csv in [cache]
class StatsCountOccurrences extends ConversationTransformer {
  /// Pattern counts
  final LinkedHashMap<Pattern, int> counts;

  /// Patterns
  IList<Pattern> _patterns;

  /// Output file path
  final File file;

  /// Cache keys
  final IList<String> _keys;

  /// If append is false the file will be overwritten.
  final bool append;

  /// The column of the pattern in the packed csv
  final int patternCol;

  /// A new column inserted with the counts
  final int countCol;

  /// Whether the patterns should be interpreted as regex
  final bool regex;

  /// Whether the pattern should be case sensitive. This is ignored if [regex] is true.
  final bool caseSensitive;

  final int min;

  /// Create a new instance
  StatsCountOccurrences(super.config, {required super.cache})
      // ignore: prefer_collection_literals
      : counts = LinkedHashMap(),
        _patterns = [
          for (String pattern in config['patterns'] ?? [])
            config['regex'] ?? false ? RegExp(pattern) : pattern
        ].lockUnsafe,
        file = File(config['path']
            .toString()
            .replaceAll('%worker%', Isolate.current.debugName ?? '0')),
        append = config['append'] ?? false,
        patternCol = config['patternCol'] ?? 0,
        countCol = config['countCol'] ?? 1,
        regex = config['regex'] ?? false,
        caseSensitive = bool.tryParse(config['caseSensitive'] ?? '') ?? true,
        min = config['min'] ?? 0,
        _keys = [
          for (var e in config['packedPatterns'] ?? const []) e.toString()
        ].lockUnsafe {
    _patterns = _patterns.addAll(_loadPackedPatterns(_keys, cache,
        regex: regex, caseSensitive: caseSensitive, patternCol: patternCol));
  }

  static IList<Pattern> _loadPackedPatterns(
      final IList<String> keys, PackedDataCache? cache,
      {bool regex = false, bool caseSensitive = true, int patternCol = 0}) {
    if (cache == null) return const IListConst([]);
    List<Pattern> newPatterns = [];
    for (String key in keys) {
      PackedData? data = cache[key];
      if (data == null) {
        _log.warning("Unable to load packed patterns '$key'");
        continue;
      }

      // Unpack, read as CSV, add to patterns list.
      List<List<String>> csvData =
          CsvToListConverter().convert(String.fromCharCodes(data.unpack()));
      if (regex) {
        // TODO Regex options
        newPatterns
            .addAll(csvData.map((List<String> e) => RegExp(e[patternCol])));
      } else {
        if (caseSensitive) {
          newPatterns.addAll(csvData.map((List<String> e) =>
              e[patternCol].toString().replaceAll(r"\n", "\n")));
        } else {
          newPatterns.addAll(csvData.map((List<String> e) =>
              e[patternCol].toString().replaceAll(r"\n", "\n").toLowerCase()));
        }
      }
    }

    return newPatterns.lockUnsafe;
  }

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> conversations in stream) {
      for (Conversation conversation in conversations) {
        for (Message message in conversation.messages) {
          String compareValue = message.value;
          if (!regex && !caseSensitive) {
            compareValue = compareValue.toLowerCase();
          }
          for (Pattern pattern in _patterns) {
            int count = pattern.allMatches(compareValue).length;
            counts.update(pattern, (value) => value + count,
                ifAbsent: () => count);
          }
        }
      }
      yield conversations;
    }

    // Write counts
    IOSink sink = (await file.create(recursive: true))
        .openWrite(mode: append ? FileMode.append : FileMode.write);
    ListToCsvConverter encoder = ListToCsvConverter();
    CsvToListConverter decoder = CsvToListConverter();
    StringBuffer sb = StringBuffer();

    IList<String> keys =
        [for (var e in config['packedPatterns'] ?? []) e.toString()].lockUnsafe;

    HashSet<String> duplicates = HashSet();
    for (String key in keys) {
      List<List> csvData =
          decoder.convert(String.fromCharCodes(cache![key]!.unpack()));
      // Create a new row from the first occurrence in the pattern list
      for (List row in csvData) {
        String? pattern = row.getOrNull(patternCol)?.toString();
        if (pattern == null) continue;

        if (duplicates.add(pattern)) {
          int count = counts[pattern] ?? 0;
          if (count < min) continue;
          List newRow = List.from(row);
          // Insert count column
          if (countCol <= newRow.length) {
            newRow.insert(countCol, count);
          } else {
            newRow.addAll(List.filled(countCol - newRow.length, ''));
            newRow.insert(countCol, count);
          }
          encoder.convertSingleRow(sb, newRow, returnString: false);
          // Write
          sink.write(sb.toString());
          sink.write('\r\n');
          sb.clear();
        }
      }
    }

    sb.clear();
    await sink.flush();
    await sink.close();
  }
}
