import '';
import 'conversation_transformer.dart';

export './builtin/encoding.dart' show Encoding;
export './builtin/exact_replace.dart' show ExactReplace;
export './builtin/full_match.dart' show FullMatch;
export './builtin/html_strip.dart' show HtmlStrip;
export './builtin/output/raw_output.dart' show RawOutput;
export './builtin/participants.dart' show Participants, RenameParticipants;
export './builtin/regex_replace.dart' show RegexReplace;
export './builtin/trim.dart' show Trim;
export './conversation_transformer.dart' show ConversationTransformer;
export 'builtin/input/csv_input.dart' show CsvInput;
export 'builtin/input/fastchat_input.dart' show FastChatInput;
export 'builtin/output/csv_output.dart' show CsvOutput;
export 'builtin/output/dsbuild_output.dart' show DsBuildOutput;
export 'builtin/output/fastchat_output.dart' show FastChatOutput;
export 'builtin/output/file_concatenate.dart' show FileConcatenate;
export 'builtin/output/regex_output.dart' show RegexOutput;

/// Maps builder names to their builder functions.
Map<String, ConversationTransformerBuilderFn> defaultTransformers() {
  return {
    'Participants': (config, progress) => Participants(config),
    'HtmlStrip': (config, progress) => HtmlStrip(config),
    'RenameParticipants': (config, progress) => RenameParticipants(config),
    'Encoding': (config, progress) => Encoding(config),
    'Trim': (config, progress) => Trim(config),
    'RegexReplace': (config, progress) => RegexReplace(config),
    'RegexExtract': (config, progress) => RegexOutput(config),
    'CsvInput': (config, progress) => CsvInput(config, progress: progress),
    'CsvOutput': (config, progress) => CsvOutput(config),
    'ExactReplace': (config, progress) => ExactReplace(config),
    'FullMatch': (config, progress) => FullMatch(config),
    'FastChatInput': (config, progress) => FastChatInput(config),
    'FastChatOutput': (config, progress) => FastChatOutput(config),
    'FileConcatenate': (config, progress) => FileConcatenate(config),
    'RawOutput': (config, progress) => RawOutput(config),
    'DsBuildOutput': (config, progress) => DsBuildOutput(config),
  };
}
