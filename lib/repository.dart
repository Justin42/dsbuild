import 'package:logging/logging.dart';

import 'model/descriptor.dart';

final Logger log = Logger("dsbuild/Repository");

/// Responsible for storing data during the build process.
class Repository {
  final DatasetDescriptor descriptor;

  const Repository(this.descriptor);
}
