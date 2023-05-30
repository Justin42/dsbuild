import 'descriptor.dart';

/// Responsible for storing data during the build process.
class Repository {
  final DatasetDescriptor descriptor;

  void updateInputHash(String path, String hash) {
    for (PassDescriptor pass in descriptor.passes) {
      for (int i = 0; i < pass.inputs.length; i++) {
        InputDescriptor current = pass.inputs[0];
        if (current.path == path) {
          pass.inputs[i] = current.copyWith(hash: hash);
        }
      }
    }
  }

  const Repository(this.descriptor);
}
