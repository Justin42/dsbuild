/// Implement or interact with custom readers.
/// Readers can be created to provide input from any source.
library reader;

export 'src/reader.dart' show Reader;
export 'src/readers/csv_reader.dart' show CsvReader;
export 'src/readers/fastchat_reader.dart' show FastChatReader;
