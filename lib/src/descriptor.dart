import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// Configuration used exclusively (and optionally) by build script implementations.
///
/// This is never sent to local or remote workers.
class BuildConfig {
  /// Generate hashes for requirements and artifacts.
  final bool generateHashes;

  /// Verify hashes of required inputs.
  final bool verifyRequirements;

  /// Verify hashes of artifacts.
  final bool verifyArtifacts;

  /// Number of conversations per batch.
  final int conversationBatch;

  /// Number of local worker threads.
  final int? threads;

  /// Remote endpoints mapped by group name
  final Map<String, List<String>> remote;

  /// Clean directory before build.
  final List<String> cleanDirectory;

  /// Create a new instance
  const BuildConfig(
      {this.generateHashes = true,
      this.verifyRequirements = false,
      this.verifyArtifacts = true,
      this.conversationBatch = 100,
      this.sendPackedFiles = false,
      this.threads,
      this.remote = const {},
      this.cleanDirectory = const []});

  /// Create a new instance from Yaml
  BuildConfig.fromYaml(YamlMap data)
      : generateHashes = data['generateHashes'] ?? true,
        verifyRequirements = data['verifyRequirements'] ?? false,
        verifyArtifacts = data['verifyHashes'] ?? true,
        conversationBatch = data['conversationBatch'] ?? 100,
        sendPackedFiles = data['sendPackedFiles'] ?? false,
        threads = data['concurrency']?['local'],
        remote = {
          for (var (String group, List members)
              in data['concurrency']?['remote'] ?? const {})
            group: [for (var member in members) member.toString()]
        },
        cleanDirectory = [
          for (var dir in data['cleanDirectory'] ?? []) dir.toString()
        ];
}

/// Describes a set of transformations on a dataset.
class DatasetDescriptor {
  /// Name
  final String name;

  /// Description
  final String description;

  /// Build configuration.
  final BuildConfig build;

  /// Transformation passes.
  final List<PassDescriptor> passes;

  /// Create a new descriptor
  const DatasetDescriptor(
      {this.name = 'default',
      this.description = 'No description',
      this.build = const BuildConfig(),
      this.passes = const []});

  /// Create a descriptor from Yaml
  DatasetDescriptor.fromYaml(YamlMap data)
      : name = data['name'] ?? 'default',
        description = data['description'] ?? 'No description',
        build = BuildConfig.fromYaml(data['build']),
        passes = [
          for (var pass in data['passes']) PassDescriptor.fromYaml(pass)
        ];
}

/// Described the transformation steps, required input, and artifacts of a transformation pass.
class PassDescriptor {
  /// The transformation steps in the pass
  final List<StepDescriptor> steps;

  /// Required input
  final List<RequirementDescriptor> required;

  /// Output artifacts
  final List<ArtifactDescriptor> artifacts;

  /// Create a new descriptor with the specified transformation [steps]
  const PassDescriptor(this.steps, this.required, this.artifacts);

  /// Create a new instance from a Yaml map
  PassDescriptor.fromYaml(YamlMap data)
      : steps = [for (var step in data['steps']) StepDescriptor.fromYaml(step)],
        required = [
          for (var requirement in data['required'])
            RequirementDescriptor.fromYaml(requirement)
        ],
        artifacts = [
          for (var artifact in data['artifacts'])
            ArtifactDescriptor.fromYaml(artifact)
        ];
}

/// Describes a requirement
class RequirementDescriptor {
  /// File path
  final String path;

  /// Source URI
  final String? source;

  /// SHA512 hash
  final String? sha512;

  /// Create a new instance
  const RequirementDescriptor(this.path, this.source, this.sha512);

  /// Create a new instance from a Yaml map
  RequirementDescriptor.fromYaml(YamlMap data)
      : path = data['path'],
        source = data['source'],
        sha512 = data['sha512'];

  /// Create a copy of this instance with the supplied values.
  RequirementDescriptor copyWith(
          {String? path, String? source, String? sha512}) =>
      RequirementDescriptor(
          path ?? this.path, source ?? this.source, sha512 ?? this.sha512);
}

/// Describes an output artifact
class ArtifactDescriptor {
  /// File path
  final String file;

  /// SHA512 hash
  final String? sha512;

  /// Create a new instance
  const ArtifactDescriptor(this.file, this.sha512);

  /// Create a descriptor from Yaml
  ArtifactDescriptor.fromYaml(YamlMap data)
      : file = data['file'],
        sha512 = data['sha512'];
}

/// Describes a transformation step.
class StepDescriptor {
  /// The type of the [ConversationTransformer]
  final String type;

  /// Description of the step
  final String description;

  final String? _sync;

  /// Configuration passed to the [ConversationTransformer]
  final Map<String, dynamic> config;

  /// Sync target
  SyncStrategy get sync => SyncStrategy.fromString(_sync);

  /// Create a new instance
  const StepDescriptor(this.type, this.description,
      {this.config = const {}, String? sync})
      : _sync = sync;

  @override
  String toString() {
    return type;
  }

  /// Create a new instance from a Yaml map
  StepDescriptor.fromYaml(YamlMap data)
      : type = data['type'],
        description = data['description'] ?? '',
        _sync = data['sync'],
        config = {if (data['config'] != null) ...data['config']};
}

/// Strategy for syncing transformation steps.
@immutable
class SyncStrategy {
  /// Target host
  final SyncTarget target;

  /// Group name for remote targets
  final String? name;

  /// Auto
  static final SyncStrategy auto = const SyncStrategy(SyncTarget.auto);

  /// Main thread
  static final SyncStrategy main = const SyncStrategy(SyncTarget.main);

  /// Local worker
  static final SyncStrategy local = const SyncStrategy(SyncTarget.local);

  /// Remote worker
  static final SyncStrategy remote = const SyncStrategy(SyncTarget.remote);

  /// Create a new instance
  const SyncStrategy(this.target, {this.name});

  /// Create a new instance from a string.
  factory SyncStrategy.fromString(String? sync) {
    sync = (sync ?? 'local').toLowerCase();
    return switch (sync) {
      'auto' => SyncStrategy.auto,
      'main' => SyncStrategy.main,
      'local' => SyncStrategy.local,
      'remote' => SyncStrategy.remote,
      _ => SyncStrategy.remote.copyWith(name: sync)
    };
  }

  @override
  String toString() {
    return name != null ? '${target.name}:$name' : target.name;
  }

  /// Create a copy of this instance with the supplied values.
  SyncStrategy copyWith({SyncTarget? target, String? name}) =>
      SyncStrategy(target ?? this.target, name: name ?? this.name);

  /// Convert the object to a JSON compatible map
  Map toJson() {
    return {'target': target.name, 'name': name}
      ..removeWhere((key, value) => value == null);
  }
}

/// Target host
enum SyncTarget {
  /// Auto
  auto,

  /// Main thread
  main,

  /// Local worker
  local,

  /// Remote worker
  remote
}
