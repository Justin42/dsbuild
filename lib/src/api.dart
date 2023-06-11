import 'dart:async';
import 'dart:io';

import 'package:dsbuild/src/transformers/transformers.dart';
import 'package:logging/logging.dart';

import '../concurrency.dart';
import 'conversation.dart';
import 'descriptor.dart';
import 'progress.dart';
import 'registry.dart';
import 'repository.dart';

/// Build a transformation pipeline from a [DatasetDescriptor]
///
/// Provides transparent dispatching to a [WorkerPool]
class DsBuild {
  /// Stores data during the build process.
  final Repository repository;

  /// Allows registering additional transformers.
  final Registry registry;

  /// Progress events.
  final ProgressBloc progress;

  /// Convenience getter for the build configuration.
  BuildConfig get build => repository.descriptor.build;

  /// Manage the [WorkerPool]
  ///
  /// Available workers are used transparently.
  /// See [DatasetDescriptor.threads] and [DatasetDescriptor.remote]
  /// Execution strategy can be changed via [StepDescriptor.sync]
  final WorkerPool workerPool;

  static final Logger _log = Logger("dsbuild");

  /// A map of available builtin transformers. Additional transformers should be registered via the [Registry]

  /// A [DatasetDescriptor] is required.
  DsBuild(DatasetDescriptor descriptor, ProgressBloc? progress,
      {Registry? registry, WorkerPool? workerPool})
      : repository = Repository(descriptor),
        registry = registry ?? Registry({}),
        progress = ProgressBloc(ProgressState()),
        workerPool = workerPool ?? WorkerPool() {
    if (registry == null) {
      this.registry.transformers.addAll(defaultTransformers());
    }
  }

  /// Verify the descriptor is valid and all required transformers are registered.
  List<String> verifyDescriptor() {
    List<String> errors = [];

    for (PassDescriptor pass in repository.descriptor.passes) {
      // Verify transformers
      // TODO Query remote workers for capabilities.
      for (StepDescriptor step in pass.steps) {
        if (!registry.transformers.containsKey(step.type)) {
          errors.add("No transformer matching type '${step.type}'");
        }
      }
    }
    return errors;
  }

  /// Fetch all requirements.
  /// yields an InputDescriptor for each newly satisfied dependency.
  Stream<RequirementDescriptor> fetchRequirements() async* {
    HttpClient client = HttpClient();
    for (PassDescriptor pass in repository.descriptor.passes) {
      for (RequirementDescriptor required in pass.required) {
        if (required.source == null || required.source!.isEmpty) continue;
        if (await File(required.path).exists()) continue;
        Uri uri = Uri.parse(required.source!);
        if (!['http', 'https'].contains(uri.scheme)) {
          _log.severe("Unhandled URI input: '${required.source}'");
          continue;
        }
        _log.info("Retrieving ${required.source}");
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          _log.warning(
              "Failed to retrieve input data. Received http status ${response.statusCode}");
          await response.drain();
        } else {
          File file = await File(required.path).create(recursive: true);
          await response.pipe(file.openWrite());
        }
        yield required;
      }
    }
    client.close();
  }

  List<(SyncStrategy, List<StepDescriptor>)> _groupByTarget(
      Iterable<StepDescriptor> steps) {
    final List<(SyncStrategy, List<StepDescriptor>)> groups = [];
    List<StepDescriptor> group = [];
    for (StepDescriptor step in steps) {
      if (group.isEmpty || step.sync == group[0].sync) {
        group.add(step);
      } else {
        groups.add((group[0].sync, group));
        group = [];
        group.add(step);
      }
    }
    if (group.isNotEmpty) {
      groups.add((group[0].sync, group));
    }
    return groups;
  }

  Stream<List<Conversation>> _dispatchTransform(
      Stream<List<Conversation>> stream, final List<StepDescriptor> steps) {
    List<(SyncStrategy, List<StepDescriptor>)> grouped = _groupByTarget(steps);
    _log.info(grouped);
    for (var (SyncStrategy sync, List<StepDescriptor> group) in grouped) {
      for (StepDescriptor step in group) {
        switch (sync.target) {
          case SyncTarget.main:
            stream = stream.transform(
                registry.transformers[step.type]!.call(step.config, progress));
            break;
          case SyncTarget.local:
            stream = workerPool.transform(stream, group);
            break;
          case SyncTarget.remote:
            throw UnimplementedError();
          case SyncTarget.auto:
            throw UnimplementedError();
        }
        // The entire group is passed to workers.
        if (sync.target == SyncTarget.local ||
            sync.target == SyncTarget.remote) {
          break;
        }
      }
    }
    return stream;
  }

  /// A convenience function to build a new pipeline from a [Repository.descriptor]
  /// Remote worker groups should be previously registered with the [workerPool]
  Stream<List<Conversation>> buildPipeline(List<StepDescriptor> steps,
      {List<Conversation> initialElements = const [],
      bool enableProgress = true}) async* {
    Stream<List<Conversation>> stream = Stream.empty();

    stream = _dispatchTransform(stream, steps);

    if (enableProgress) {
      stream = stream.transform(StreamTransformer.fromHandlers(
          handleData: (List<Conversation> data, Sink<List<Conversation>> sink) {
        progress.add(ConversationProcessed(count: data.length));
        progress.add(MessageProcessed(count: data.messageCount));
      }));
    }

    yield* stream;
  }
}
