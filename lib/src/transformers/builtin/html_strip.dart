import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:logging/logging.dart';

import '../../conversation.dart';
import '../preprocessor.dart';

Logger _log = Logger("dsbuild/transformers");

class HtmlStrip extends Preprocessor {
  final bool caseSensitive;
  final IList<Pattern> stripAnchorPatterns;
  final String anchorSelector;

  int strippedAnchors = 0;

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
  StreamTransformer<MessageEnvelope, MessageEnvelope> get transformer =>
      StreamTransformer.fromHandlers(handleData: (data, sink) {
        DocumentFragment fragment = parseFragment(data.message.value);
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
        sink.add(data.copyWithValue(fragment.text ?? ""));
      }, handleDone: (sink) {
        _log.finer("$runtimeType stripped $strippedAnchors anchor texts.");
        sink.close();
      });
}
