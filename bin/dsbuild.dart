import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dsbuild/dsbuild.dart';
import 'package:dsbuild/progress.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  final Logger log = Logger("dsbuild");

  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    print(
        '${record.time.toUtc()}/${record.level.name}/${record.loggerName}: ${record.message}');
  });

  String descriptorPath = args.isEmpty ? 'dataset.yaml' : args[0];

  // Create dataset descriptor
  log.config("Loading dataset descriptor from '$descriptorPath'");
  DatasetDescriptor descriptor;
  try {
    YamlMap data = loadYaml(await File(descriptorPath).readAsString());
    //print(data.toString());
    descriptor = DatasetDescriptor.fromYaml(data);
  } on PathNotFoundException catch (ex) {
    log.severe("No descriptor found at $descriptorPath: ${ex.message}");
    exit(1);
  }

  int deletedFiles = 0;
  for (String dir in descriptor.cleanDirectory) {
    if (dir.contains("../") || dir.contains(r"..\")) {
      throw Exception("Clean directory escapes working directory");
    }
    Directory directory =
        Directory(p.relative(dir, from: Directory.current.path));
    log.info("Cleaning build directory '${p.relative(directory.path)}'");
    await directory.list().forEach((element) {
      element.delete(recursive: true);
      deletedFiles++;
    });
  }
  log.info("Removed $deletedFiles files");

  // Initialize DsBuild
  DsBuild dsBuild = DsBuild(descriptor);
  await dsBuild.workerPool
      .startLocalWorkers(descriptor.threads ?? Platform.numberOfProcessors);
  log.info("${dsBuild.workerPool.workers.length} active workers.");

  // Progress output
  DateTime startTime = DateTime.timestamp();
  DateTime lastProgressOutput = DateTime.timestamp();
  dsBuild.progress.stream.listen((state) {
    if (DateTime.timestamp().difference(lastProgressOutput).inSeconds > 5) {
      lastProgressOutput = DateTime.timestamp();
      log.fine("Progress:\n"
          "Messages processed: ${state.messagesProcessed} / ${state.messagesTotal}\n"
          "Conversations processed: ${state.conversationsProcessed} / ${state.conversationsTotal}");
    }
  }, onDone: () {
    ProgressState state = dsBuild.progress.state;
    log.fine("Progress:\n"
        "Messages processed: ${state.messagesProcessed} / ${state.messagesTotal}\n"
        "Conversations processed: ${state.conversationsProcessed} / ${state.conversationsTotal}");
  });

  // Additional transformers can be registered.
  //dsBuild.registry.registerPreprocessor(name, (config) => Preprocessor())

  log.info("Validating descriptor.");
  List<String> errors = dsBuild.verifyDescriptor();
  if (errors.isNotEmpty) {
    for (String validationError in dsBuild.verifyDescriptor()) {
      log.severe(validationError);
      exit(1);
    }
  } else {
    log.config("Descriptor valid.");
  }

  await dsBuild.fetchRequirements().forEach((input) async {
    log.info("${input.source} retrieved.");
  });

  if (dsBuild.repository.descriptor.generateHashes ||
      dsBuild.repository.descriptor.verifyHashes) {
    for (PassDescriptor pass in dsBuild.repository.descriptor.passes) {
      for (int i = 0; i < pass.inputs.length; i++) {
        final InputDescriptor descriptor = pass.inputs[i];
        String hash = (await sha512.bind(File(descriptor.path).openRead()).last)
            .toString();
        if (dsBuild.repository.descriptor.verifyHashes &&
            descriptor.hash != null) {
          if (descriptor.hash != hash) {
            throw FileVerificationError(descriptor.path,
                descriptor.source.toString(), descriptor.hash!, hash);
          }
        } else if (descriptor.hash != hash) {
          dsBuild.repository.updateInputHash(descriptor.path, hash);
        }
        log.info(
            "Hash Result:\nFile: ${descriptor.path}\nSource: ${descriptor.source}\nsha512: $hash");
      }
    }
  }

  for (var (int i, PassDescriptor pass)
      in dsBuild.repository.descriptor.passes.indexed) {
    log.info("Preparing pipeline...");
    Stream<Conversation> conversations = dsBuild.transformAll(pass);

    log.info("Performing transformations...");
    await dsBuild.writeAll(pass, conversations).last;
    dsBuild.progress.add(i + 1 < dsBuild.repository.descriptor.passes.length
        ? const PassComplete(resetCounts: true)
        : const PassComplete(resetCounts: false));
    log.info(
        "Pass ${i + 1} / ${dsBuild.repository.descriptor.passes.length} completed.");
  }
  log.finer("Stopping local workers.");
  dsBuild.workerPool.stopLocalWorkers();
  dsBuild.progress.add(const BuildComplete());

  log.info("All output finalized.");

  if (dsBuild.repository.descriptor.generateHashes ||
      dsBuild.repository.descriptor.verifyHashes) {
    log.info("Generating output file hashes.");
    for (PassDescriptor pass in dsBuild.repository.descriptor.passes) {
      for (OutputDescriptor descriptor in pass.outputs) {
        String hash = (await sha512.bind(File(descriptor.path).openRead()).last)
            .toString();
        if (dsBuild.repository.descriptor.verifyHashes &&
            descriptor.hash != null &&
            descriptor.hash != hash) {
          log.severe(FileVerificationError(
              descriptor.path, "", descriptor.hash!, hash));
        } else {
          log.info(
              "Hash Result:\nFile: ${descriptor.path}\nSource: ${descriptor.path}\nsha512: $hash");
        }
      }
    }
  }
  await dsBuild.progress.close();
  Duration duration = DateTime.timestamp().difference(startTime);
  log.info("Build completed in $duration");
}
