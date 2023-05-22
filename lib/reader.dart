/// Read messages from a source. See [Reader] for implementing custom readers.
library reader;

export 'src/reader.dart' show Reader;
export 'src/readers/csv_reader.dart' show CsvReader;
export 'src/readers/fastchat_reader.dart' show FastChatReader;
