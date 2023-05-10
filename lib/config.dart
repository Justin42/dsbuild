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
    switch (mode.toLowerCase()) {
      case 'prune':
        return prune;
      case 'strip':
        return strip;
      default:
        return null;
    }
  }
}
