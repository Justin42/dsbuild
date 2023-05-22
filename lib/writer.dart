/// Output the final conversation stream.
/// See [Writer] for implementing custom writers.
library writer;

export 'src/writer.dart' show Writer;
export 'src/writers/dsbuild_writer.dart' show DsBuildWriter;
export 'src/writers/fastchat_writer.dart' show FastChatWriter;
