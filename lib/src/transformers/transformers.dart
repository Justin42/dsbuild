import 'package:dsbuild/src/transformers/builtin/stats/stats_prune.dart';

import '';

export 'builtin/encoding.dart' show Encoding;
export 'builtin/exact_replace.dart' show ExactReplace;
export 'builtin/full_match.dart' show FullMatch;
export 'builtin/html_strip.dart' show HtmlStrip;
export 'builtin/input/csv_input.dart' show CsvInput;
export 'builtin/input/fastchat_input.dart' show FastChatInput;
export 'builtin/output/csv_output.dart' show CsvOutput;
export 'builtin/output/dsbuild_output.dart' show DsBuildOutput;
export 'builtin/output/fastchat_output.dart' show FastChatOutput;
export 'builtin/output/file_concatenate.dart' show FileConcatenate;
export 'builtin/output/raw_output.dart' show RawOutput;
export 'builtin/output/raw_sample_output.dart' show RawSampleOutput;
export 'builtin/output/regex_output.dart' show RegexOutput;
export 'builtin/participants.dart' show Participants, RenameParticipants;
export 'builtin/regex_replace.dart' show RegexReplace;
export 'builtin/stats/add_column_merge.dart' show StatsAddColMerge;
export 'builtin/stats/count_occurrences.dart' show StatsCountOccurrences;
export 'builtin/stats/stats_output.dart' show StatsOutput;
export 'builtin/trim.dart' show Trim;
export 'conversation_transformer.dart'
    show ConversationTransformer, ConversationTransformerBuilderFn;

/// Maps transformer names to their builder functions.
Map<String, ConversationTransformerBuilderFn> defaultTransformers() => {
      'Participants': (config, progress, cache) => Participants(config),
      'HtmlStrip': (config, progress, cache) => HtmlStrip(config),
      'RenameParticipants': (config, progress, cache) =>
          RenameParticipants(config),
      'Encoding': (config, progress, cache) => Encoding(config),
      'Trim': (config, progress, cache) => Trim(config),
      'RegexReplace': (config, progress, cache) => RegexReplace(config),
      'RegexExtract': (config, progress, cache) => RegexOutput(config),
      'CsvInput': (config, progress, cache) =>
          CsvInput(config, progress: progress),
      'CsvOutput': (config, progress, cache) => CsvOutput(config),
      'ExactReplace': (config, progress, cache) =>
          ExactReplace(config, cache: cache),
      'FullMatch': (config, progress, cache) => FullMatch(config),
      'FastChatInput': (config, progress, cache) =>
          FastChatInput(config, progress: progress),
      'FastChatOutput': (config, progress, cache) => FastChatOutput(config),
      'FileConcatenate': (config, progress, cache) => FileConcatenate(config),
      'RawOutput': (config, progress, cache) => RawOutput(config),
      'DsBuildOutput': (config, progress, cache) => DsBuildOutput(config),
      'StatsCountOccurrences': (config, progress, cache) =>
          StatsCountOccurrences(config, cache: cache),
      'StatsAddColMerge': (config, progress, cache) => StatsAddColMerge(config),
      'StatsOutput': (config, progress, cache) => StatsOutput(config),
      'StatsConversationPrune': (config, progress, cache) =>
          StatsConversationPrune(config, cache: cache),
      'RawSampleOutput': (config, progress, cache) => RawSampleOutput(config),
    };
