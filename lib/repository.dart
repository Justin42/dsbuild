import 'model/descriptor.dart';

/// Responsible for storing data during the build process.
class Repository {
  final DatasetDescriptor descriptor;

  void updateInputHash(Uri uri, String hash) {
    for (int i = 0; i < descriptor.inputs.length; i++) {
      InputDescriptor current = descriptor.inputs[i];
      if (current.source == uri) {
        descriptor.inputs[i] = current.copyWith(hash: hash);
      }
    }
  }

  const Repository(this.descriptor);
}
