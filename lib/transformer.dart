/// Transformations for messages or conversations.
/// For implementing message transformers see [Preprocessor]
/// For implementing conversation transformers see [Postprocessor]
library transformer;

export 'src/transformers/postprocessor.dart' show Postprocessor;
export 'src/transformers/preprocessor.dart' show Preprocessor;
export 'src/transformers/transformers.dart';
