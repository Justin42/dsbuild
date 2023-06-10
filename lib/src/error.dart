/// Thrown during hash verification failures
class FileVerificationError {
  /// File path
  final String path;

  /// File source
  final String source;

  /// Expected hash
  final String expected;

  /// Actual hash
  final String actual;

  /// Create a new instance
  const FileVerificationError(
      this.path, this.source, this.expected, this.actual);

  @override
  String toString() {
    return "Hash verification failed.\nFile: $path\nSource: $source\nExpected: $expected\nActual: $actual";
  }
}
