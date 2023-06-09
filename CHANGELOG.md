*0.1.0-alpha.6:*

- Better progress display.
- No longer hash required files when `build.verifyRequirements` is false.
- `StatsOutput` and `StatsConversationPrune` transformers
- API for generating statistics, allows implementing custom generators.
- Simple tokenizer, provides vocabulary and word counts for statistics.

---
*0.1.0-alpha.5:*

- Required binary data can now be pushed to workers.
- `ConversationTransformers` can now push `MessageRead` and `ConversationRead` events.
- Fix unhandled exception on missing artifact (now a warning)
- Allow FileConcatenate to create new directories and overwrite existing files.
- ExactReplace can now use external csv data (using the new `PackedDataCache`)
- Implement new transformers `StatsCountOccurrences` and `StatsAddColMerge`
- `HtmlStrip` can now strip elements by dom query

---
*0.1.0-alpha.4:*

- Simplified API and pipeline (major breaking changes)
- Configurable dispatching replaces readers/writers.
- `ConversationTransformer` replaces `Preprocessor` and `Postprocessor`.
- `required` and `artifacts` config section replaces input/output descriptors.

---
*0.1.0-alpha.3:*

- Multithreading
- Multiple passes
- Additional transformers

---
