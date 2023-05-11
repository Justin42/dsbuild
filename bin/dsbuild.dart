// major beta (3.0.0) API usage.
// ignore_for_file: sdk_version_since

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dsbuild/dsbuild.dart';
import 'package:dsbuild/error.dart';
import 'package:dsbuild/model/conversation.dart';
import 'package:dsbuild/model/descriptor.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  final Logger log = Logger("dsbuild");

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
        '${record.time}/${record.level.name}/${record.loggerName}: ${record.message}');
  });

  String descriptorPath = args.isEmpty ? 'dataset.yaml' : args[0];

  // Create dataset descriptor
  log.config("Loading dataset descriptor from '$descriptorPath'");
  DatasetDescriptor descriptor;
  try {
    YamlMap data = loadYaml(await File(descriptorPath).readAsString());
    descriptor = DatasetDescriptor.fromYaml(data);
  } on PathNotFoundException catch (ex) {
    log.severe("No descriptor found at $descriptorPath: ${ex.message}");
    exit(1);
  }

  // Initialize DsBuild
  DsBuild dsBuild = DsBuild(descriptor);

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

  // Retrieve and verify input
  {
    List<FileVerificationError> hashErrors = [];
    List<InputDescriptor> hashUpdates = [];
    await dsBuild.fetchRequirements().forEach((input) async {
      if (input.hash != null) {
        log.info("Verifying hash for ${input.path}");
        Digest hash = await sha512.bind(File(input.path).openRead()).last;
        if (hash.toString() != input.hash!) {
          FileVerificationError error = FileVerificationError(
              input.path, input.source, input.hash!, hash.toString());
          log.severe(error);
          hashErrors.add(error);
        } else {
          log.config("Verified hash for ${input.path}");
        }
      } else if (dsBuild.repository.descriptor.generateHashes) {
        log.info("Generating hash for ${input.path}");
        Digest hash = await sha512.bind(File(input.path).openRead()).last;
        log.info(
            "Generated SHA512 hash.\nFile: ${input.path}\nSource: ${input.source}\nsha512: ${hash.toString()}");
        hashUpdates.add(input.copyWith(hash: hash.toString()));
      }
    });
    if (hashErrors.isNotEmpty) {
      exit(1);
    }

    // Update descriptors with any newly generated hashes.
    for (InputDescriptor input in hashUpdates) {
      dsBuild.repository.updateInputHash(input.source, input.hash!);
    }
  }

  // Stats and progress tracking
  Map<String, dynamic> stats = {
    'Total Conversations': 0,
    'Start Time': DateTime.timestamp(),
    'Elapsed': Duration
  };

  StreamTransformer<Conversation, Conversation> statTracker =
      StreamTransformer.fromHandlers(handleData: (data, sink) {
    stats['Total Conversations'] += 1;
    sink.add(data);
  }, handleDone: (sink) {
    stats['Elapsed'] = DateTime.timestamp().difference(stats['Start Time']);
    log.info(jsonEncode(stats, toEncodable: (obj) => obj.toString()));
    sink.close();
  });

  log.info("Preparing pipeline...");
  Stream<Conversation> conversations =
      dsBuild.transformAll().transform(statTracker);

  log.info("Performing transformations...");
  await dsBuild.writeAll(conversations).drain();
}
