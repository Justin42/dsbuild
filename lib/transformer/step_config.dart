import 'package:logging/logging.dart';

final Logger log = Logger("dsbuild");

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
        log.warning(
            "Unrecognized removal mode '$mode'. Valid values are: 'prune', 'strip'");
        return null;
    }
  }
}
