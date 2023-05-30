import 'dart:async';
import 'dart:io';

import 'package:dsbuild/dsbuild.dart';
import 'package:dsbuild/progress.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  // Load a descriptor. You can also build a descriptor programmatically.
  String descriptorPath = args.isEmpty ? 'dataset.yaml' : args[0];
  DsBuild dsBuild = DsBuild(DatasetDescriptor.fromYaml(
      loadYaml(await File(descriptorPath).readAsString())));

  // Listen to progress events
  DateTime lastProgressOutput = DateTime.timestamp();
  dsBuild.progress.stream.listen((state) {
    if (DateTime.timestamp().difference(lastProgressOutput).inSeconds > 5) {
      lastProgressOutput = DateTime.timestamp();
      print("Progress:\n"
          "Messages processed: ${state.messagesProcessed} / ${state.messagesTotal}\n"
          "Conversations processed: ${state.conversationsProcessed} / ${state.conversationsTotal}");
    }
  });

  // Register additional transformers.
  // The builtin transformers can also be replaced.
  //dsBuild.registry.registerPreprocessor(name, (config) => Preprocessor())

  // verifyDescriptor is a convenience function to output a simple list of error strings for any missing transformers.
  List<String> errors = dsBuild.verifyDescriptor();
  if (errors.isNotEmpty) {
    for (String validationError in dsBuild.verifyDescriptor()) {
      print(validationError);
    }
    exit(1);
  } else {
    print("Descriptor valid.");
  }

  // fetchRequirements can be used to automatically download input files with a provided source uri.
  await dsBuild.fetchRequirements().forEach((input) async {
    print("${input.source} retrieved.");
  });

  // Now could also be a good time to verify the integrity of any downloaded files.
  // This may be included in the API in the future, as it is an expected feature of any downstream application.

  // Build the transformation pipeline. This is the result of transforming and concatenating all inputs.
  // Custom pipelines can be built using the registry and the information available in the descriptor.
  for (PassDescriptor pass in dsBuild.repository.descriptor.passes) {
    Stream<Conversation> conversations = dsBuild.transformAll(pass);

    // Write the outputs. This also applies any postprocessor transformations for each output.
    // The implementation is nearly identical to transformAll, and custom pipelines can be built the same way.
    await dsBuild.writeAll(pass, conversations).last;
  }

  // Final progress stream events are expected to be pushed by the build script.
  // This is more useful if you intend to trigger additional build steps.
  dsBuild.progress.add(const BuildComplete());
  await dsBuild.progress.close();

  print("Done!");
}
