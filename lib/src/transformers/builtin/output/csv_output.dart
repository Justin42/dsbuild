import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:csv/csv.dart';

import '../../../conversation.dart';
import '../../conversation_transformer.dart';

/// Valid message fields for CSV output
enum Field {
  /// [Message.id]
  message,

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
        String? row = csv.convertSingleRow(sb, header);
        ioSink?.write('$row\r\n');
        sb.clear();
      }
    }

    await for (List<Conversation> conversations in stream) {
      for (Conversation conversation in conversations) {
        for (Message message in conversation.messages) {
          List newRow = [];
          for (Field field in fields) {
            newRow.add(switch (field) {
              Field.message => message.id,
              Field.conversation => conversation.id,
              Field.from => message.from,
              Field.value => message.value,
              Field.hash => message.hashCode,
            });
          }
          String? row = csv.convertSingleRow(sb, newRow);
          if (row != null && row.isNotEmpty) {
            if (ignoreDuplicates) {
              if (duplicates.add(row)) {
                ioSink?.write('$row\r\n');
              }
            } else {
              ioSink?.write('$row\r\n');
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
