import 'package:dsbuild/src/transformers/packed_data.dart';

import 'descriptor.dart';

/// Responsible for storing data during the build process.
class Repository {
  /// A descriptor describing the transformations. See [DatasetDescriptor]
  final DatasetDescriptor descriptor;

  /// Binary datastore
  final PackedDataCache data;

  /// Update the sha512 hash of a required input.
  void updateInputHash(String path, String hash) {
    for (PassDescriptor pass in descriptor.passes) {
      for (int i = 0; i < pass.required.length; i++) {
        RequirementDescriptor current = pass.required[0];
        if (current.path == path) {
          pass.required[i] = current.copyWith(sha512: hash);
        }
      }
    }
  }

  /// Construct a new repository with the given descriptor.
  const Repository(this.descriptor, this.data);
}

/// A repository intended for the use in the context of a task.
class WorkerRepository {}
