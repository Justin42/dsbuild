/// Implement or interact with custom writers.
/// Writers can be implemented to output data to any destination.
library writer;

export 'src/writer.dart' show Writer;
export 'src/writers/dsbuild_writer.dart' show DsBuildWriter;
export 'src/writers/fastchat_writer.dart' show FastChatWriter;
