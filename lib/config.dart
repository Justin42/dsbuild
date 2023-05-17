class Config {
  final bool verbose;
  final bool saveLog;
  final int maxActiveDownloads;

  const Config(
      {this.verbose = false, this.saveLog = true, this.maxActiveDownloads = 2});
}

enum RemovalMode {
  prune,
  strip;

  RemovalMode? fromString(String mode) {
    return switch (mode.toLowerCase()) {
      'prune' => prune,
      'strip' => strip,
      _ => null
    };
  }
}
