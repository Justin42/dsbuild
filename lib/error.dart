class FileVerificationError {
  final String path;
  final Uri source;
  final String expected;
  final String actual;

  const FileVerificationError(
      this.path, this.source, this.expected, this.actual);

  @override
  String toString() {
    return "Hash verification failed.\nFile: $path\nSource: $source\nExpected: $expected\nActual: $actual";
  }
}
