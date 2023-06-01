import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:csv/csv.dart';
import 'package:dsbuild/src/conversation.dart';
import 'package:dsbuild/src/transformers/preprocessor.dart';

enum Field {
  conversation,
  from,
  value,
  hash,
}

class CsvExtract extends Preprocessor {
  final File file;
  final List<String> header;
  final List<Field> fields;
  final bool ignoreDuplicates;
  final HashSet<String> duplicates;
  final ListToCsvConverter csv;
  final StringBuffer sb;
  IOSink? ioSink;

  CsvExtract(super.config)
      : file = File(config['path']
            .toString()
            .replaceAll("%worker%", Isolate.current.debugName ?? '0')),
        header = [for (var col in config['header'] ?? []) col.toString()],
        fields = [
          for (var field in config['fields']) Field.values.byName(field)
        ],
        ignoreDuplicates = config['ignore_duplicates'] ?? false,
        duplicates = HashSet<String>(),
        csv = ListToCsvConverter(),
        sb = StringBuffer();

  @override
  String get description => "Extract fields to Csv";

  @override
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) async {
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
        List<String> newRow = List.filled(fields.length, '', growable: false);
        for (var (int col, Field field) in fields.indexed) {
          newRow[col] = switch (field) {
            Field.conversation => data.conversationId,
            Field.from => data.from,
            Field.value => data.value,
            Field.hash => data.hashCode.toString(),
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
        sink.add(data);
      }, handleDone: (sink) async {
        await ioSink?.flush();
        await ioSink?.close();
        sink.close();
      });
}
