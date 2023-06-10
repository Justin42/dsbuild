import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:csv/csv.dart';

import '../../../conversation.dart';
import '../../conversation_transformer.dart';

/// Valid message fields for CSV output
enum Field {
  /// [Conversation.id]
  conversation,

  /// [Message.from]
  from,

  /// [Message.value]
  value,

  /// Hash value
  hash,
}

/// Output message fields to CSV
class CsvOutput extends ConversationTransformer {
  /// Output file
  final File file;

  /// Header field names
  final List<String> header;

  /// Message fields
  final List<Field> fields;

  /// Ignore duplicates
  final bool ignoreDuplicates;

  /// Duplicates
  final HashSet<String> duplicates;

  /// Csv converter
  final ListToCsvConverter csv;

  /// String buffer
  final StringBuffer sb;

  /// Output sink
  IOSink? ioSink;

  /// Create a new instance
  CsvOutput(super.config)
      : file = File(config['path']
            .toString()
            .replaceAll("%worker%", Isolate.current.debugName ?? '0')),
        header = [for (var col in config['header'] ?? []) col.toString()],
        fields = [
          for (var field in config['fields']) Field.values.byName(field)
        ],
        ignoreDuplicates = config['ignoreDuplicates'] ?? false,
        duplicates = HashSet<String>(),
        csv = ListToCsvConverter(),
        sb = StringBuffer();

  @override
  String get description => "Extract fields to Csv";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    if (ioSink == null) {
      bool newFile = false;
      if (header.isNotEmpty && !await file.exists()) {
        newFile = true;
      }
      ioSink = file.openWrite(
          mode: (config['overwrite'] ?? false)
              ? FileMode.writeOnly
              : FileMode.append);
      if (newFile && header.isNotEmpty) {
        ioSink?.writeln(csv.convert([header]));
      }
    }

    await for (List<Conversation> conversations in stream) {
      for (Conversation conversation in conversations) {
        for (Message message in conversation.messages) {
          List<String> newRow = List.filled(fields.length, '', growable: false);
          for (var (int col, Field field) in fields.indexed) {
            newRow[col] = switch (field) {
              Field.conversation => conversation.id.toString(),
              Field.from => message.from,
              Field.value => message.value,
              Field.hash => message.hashCode.toString(),
            };
          }
          String? csvRow = csv.convertSingleRow(sb, newRow);
          if (csvRow != null && csvRow.isNotEmpty) {
            if (ignoreDuplicates) {
              if (duplicates.add(csvRow)) {
                ioSink?.writeln(csvRow);
              }
            } else {
              ioSink?.writeln(csvRow);
            }
            sb.clear();
          }
        }
      }
      yield conversations;
    }

    await ioSink?.flush();
    await ioSink?.close();
  }
}
