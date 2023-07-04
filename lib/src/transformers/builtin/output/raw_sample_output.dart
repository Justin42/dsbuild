import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dsbuild/src/transformers/conversation_transformer.dart';
import 'package:logging/logging.dart';

import '../../../conversation.dart';

final Logger _log = Logger("dsbuild/RawSampleOutput");

/// Raw message output
class RawSampleOutput extends ConversationTransformer {
  /// Output file
  final File file;

  /// Whether to filter the stream
  bool forwardFilter;

  /// Escape line endings
  bool escape;

  /// Sample ratio
  double ratio;

  /// Sample seed
  int seed;

  /// Sample batch size. Be sure that ratio * batchSize >= 1
  int batchSize;

  /// Create a new instance
  RawSampleOutput(super.config)
      : file = File(config['path'].toString()),
        forwardFilter = config['forwardFilter'] ?? false,
        escape = config['escape'] ?? false,
        ratio = config['ratio'] ?? 0.1,
        seed = config['seed'] ?? 42,
        batchSize = config['batchSize'] ?? 100;

  /// Sample the source
  static List<Conversation> sample(
      List<Conversation> source, Random rand, double ratio) {
    int sampleSize = (source.length * ratio).floor();
    List<Conversation> sample = source.toList(growable: false)..shuffle(rand);
    return sample.sublist(0, sampleSize);
  }

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    IOSink ioSink =
        await file.create(recursive: true).then((value) => value.openWrite());
    Random rand = Random(seed);

    if (batchSize * ratio < 1) {
      _log.warning(
          "Configuration will result in empty samples ($batchSize * $ratio < 1)");
    }

    List<Conversation> batch = [];
    await for (List<Conversation> conversations in stream) {
      batch.addAll(conversations);
      if (batch.length < batchSize) {
        continue;
      }

      List<Conversation> sampledBatch = batch.sublist(0, batchSize);
      List<Conversation> samples = sample(sampledBatch, rand, ratio);
      for (Conversation conversation in samples) {
        for (Message message in conversation.messages) {
          if (escape) {
            ioSink.writeln(message.value.replaceAll("\n", r"\n"));
          } else {
            ioSink.writeln(message.value);
          }
        }
      }

      batch = batch.sublist(batchSize);

      /// Yield all or samples only
      if (forwardFilter) {
        yield samples;
      } else {
        yield sampledBatch;
      }
    }

    await ioSink.flush();
    await ioSink.close();
  }
}
