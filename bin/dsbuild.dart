// major beta (3.0.0) API usage.
// ignore_for_file: sdk_version_since

import 'dart:io';

import 'package:dsbuild/api.dart';
import 'package:dsbuild/dsbuild.dart';
import 'package:dsbuild/model/descriptor.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

final Logger log = Logger("dsbuild");

void main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
        '${record.time}/${record.level.name}/${record.loggerName}: ${record
            .message}');
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
  DsBuildApi dsBuild = DsBuild(descriptor);

  log.config("Validating descriptor.");
  List<String> errors = dsBuild.verifyDescriptor();
  if (errors.isNotEmpty) {
    for (String validationError in dsBuild.verifyDescriptor()) {
      log.severe(validationError);
    }
  } else {
    log.config("Descriptor valid.");
  }

  await dsBuild.fetchRequirements().forEach((element) {
    log.info("Retrieved ${element.source}");
  });
}
