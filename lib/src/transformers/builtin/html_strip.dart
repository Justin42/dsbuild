import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:logging/logging.dart';

import '../../conversation.dart';
import '../conversation_transformer.dart';

Logger _log = Logger("dsbuild/transformers");

/// Strip HTML
class HtmlStrip extends ConversationTransformer {
  /// Case sensitive anchor patterns.
  final bool caseSensitive;

  /// Patterns to strip from anchor texts.
  final IList<Pattern> stripAnchorPatterns;

  /// DOM query for selecting anchors.
  final String anchorSelector;

  /// Anchor texts stripped.
  int strippedAnchors = 0;

  /// Constructs a new instance
  HtmlStrip(super.config)
      : caseSensitive = config['caseSensitive'] ?? true,
        stripAnchorPatterns = config['stripAnchorPatterns'] != null
            ? IList([
                for (String pattern in config['stripAnchorPatterns'])
                  config['caseSensitive'] ?? true
                      ? pattern
                      : pattern.toLowerCase()
              ])
            : const IListConst([]),
        anchorSelector = config['anchorSelector'] ?? "a, img";

  @override
  String get description => "Strip HTML";

  @override
  Stream<List<Conversation>> bind(Stream<List<Conversation>> stream) async* {
    await for (List<Conversation> batch in stream) {
      IList<Conversation> conversations = IList(batch);
      for (var (int i, Conversation conversation) in batch.indexed) {
        IList<Message> messages = IList(conversation.messages);
        for (var (int i, Message message) in messages.indexed) {
          DocumentFragment fragment = parseFragment(message.value);
          if (stripAnchorPatterns.isNotEmpty) {
            List<Element> removals = [];
            for (Element child in fragment.querySelectorAll(anchorSelector)) {
              for (Pattern pattern in stripAnchorPatterns) {
                if ((caseSensitive && child.text.contains(pattern)) ||
                    (caseSensitive &&
                        child.text.toLowerCase().contains(pattern))) {
                  removals.add(child);
                  break;
                }
              }
            }
            strippedAnchors += removals.length;
            for (Node node in removals) {
              node.remove();
            }
          }
          messages =
              messages.replace(i, message.copyWith(value: fragment.text ?? ""));
        }
        conversations =
            conversations.replace(i, conversation.copyWith(messages: messages));
      }
      yield conversations.unlockLazy;
    }
    _log.finer("$runtimeType stripped $strippedAnchors anchor texts.");
  }
}
