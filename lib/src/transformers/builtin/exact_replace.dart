import 'dart:async';

import 'package:csv/csv.dart';
import 'package:dsbuild/cache.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:logging/logging.dart';

import '../../conversation.dart';
import '../conversation_transformer.dart';

final Logger _log = Logger('dsbuild/ExactReplace');

/// Replace matches with a substitution.
class ExactReplace extends ConversationTransformer {
  /// Patterns and their substitutions.
  IList<({String match, String replace})> replacements;

  /// Match recursively
  final bool recursive;

  /// Constructs a new instance
  ExactReplace(super.config, {super.cache})
      : replacements = IList([
          for (List replacement in config['replacements'] ?? [])
            (match: replacement[0], replace: replacement[1])
        ]),
        recursive = config['recursive'] ?? false {
    List<String> keys = [
      for (var e in config['packedReplacements'] ?? []) e.toString()
    ];
    replacements = replacements.addAll(_loadPackedReplacements(keys, cache));
  }

  @override
  String get description => "Simple substitution on exact match.";

  static IList<({String match, String replace})> _loadPackedReplacements(
      List<String> keys, PackedDataCache? cache) {
    if (cache == null) return const IListConst([]);
    List<({String match, String replace})> newReplacements = [];
    for (String key in keys) {
      PackedData? data = cache[key];
      if (data == null) {
        _log.warning("Unable to load packed replacements list '$key'");
        continue;
      }
      // Unpack, read as CSV, add to replacements list.
      List<List<String>> csvData =
          CsvToListConverter().convert(String.fromCharCodes(data.unpack()));
      newReplacements.addAll(csvData.map((List<String> e) => (
            match: e[0].toString().replaceAll(r"\n", "\n"),
            replace: e.length > 1 ? e[1].toString().replaceAll(r"\n", "\n") : ''
          )));
    }
    return newReplacements.lockUnsafe;
  }

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> data in stream) {
      IList<Conversation> conversations = IList(data);
      for (var (int i, Conversation conversation) in data.indexed) {
        List<Message> messages = conversation.messages.unlockLazy;
        bool modified = false;
        for (int i = 0; i < conversation.messages.length; i++) {
          Message message = conversation.messages[i];
          String lastText = message.value;
          bool hasMatches = false;
          do {
            hasMatches = false;
            for (int i = 0; i < replacements.length; i++) {
              var (:match, :replace) = replacements[i];
              String text = lastText.replaceAll(match, replace);
              if (!identical(text, lastText)) {
                lastText = text;
                hasMatches = true;
                modified = true;
              }
            }
          } while (hasMatches && recursive);
          if (!identical(lastText, message.value)) {
            messages[i] = message.copyWith(value: lastText);
          }
        }
        if (modified) {
          conversations = conversations.replace(
              i, conversation.copyWith(messages: messages));
        }
      }
      yield conversations.unlockLazy;
    }
  }
}
