import 'descriptor.dart';

/// Responsible for storing data during the build process.
class Repository {
  final DatasetDescriptor descriptor;

  void updateInputHash(String path, String hash) {
    for (int i = 0; i < descriptor.inputs.length; i++) {
      InputDescriptor current = descriptor.inputs[i];
      if (current.path == path) {
        descriptor.inputs[i] = current.copyWith(hash: hash);
      }
    }
  }

  const Repository(this.descriptor);
}
