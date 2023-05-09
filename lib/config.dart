class Config {
  final bool verbose;
  final bool saveLog;
  final int maxActiveDownloads;

  const Config(
      {this.verbose = false, this.saveLog = true, this.maxActiveDownloads = 2});
}
