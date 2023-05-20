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
    //print(data.toString());
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

  await dsBuild.fetchRequirements().forEach((input) async {
    log.info("${input.source} retrieved.");
  });

  if (dsBuild.repository.descriptor.generateHashes ||
      dsBuild.repository.descriptor.verifyHashes) {
    for (int i = 0; i < dsBuild.repository.descriptor.inputs.length; i++) {
      final InputDescriptor descriptor =
          dsBuild.repository.descriptor.inputs[i];
      String hash =
          (await sha512.bind(File(descriptor.path).openRead()).last).toString();
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
    log.info("Preprocessing completed.");
    sink.close();
  });

  log.info("Preparing pipeline...");
  Stream<Conversation> conversations =
      dsBuild.transformAll().transform(statTracker);

  log.info("Performing transformations...");
  await dsBuild.writeAll(conversations).last;
  log.info("Output finalized.");

  if (dsBuild.repository.descriptor.generateHashes ||
      dsBuild.repository.descriptor.verifyHashes) {
    log.info("Generating output file hashes.");
    for (OutputDescriptor descriptor in dsBuild.repository.descriptor.outputs) {
      String hash =
          (await sha512.bind(File(descriptor.path).openRead()).last).toString();
      if (dsBuild.repository.descriptor.verifyHashes &&
          descriptor.hash != null &&
          descriptor.hash != hash) {
        throw FileVerificationError(
            descriptor.path, "", descriptor.hash!, hash);
      }
      log.info(
          "Hash Result:\nFile: ${descriptor.path}\nSource: ${descriptor.path}\nsha512: $hash");
    }
    log.info("Done.");
  }
}
