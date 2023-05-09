import 'package:dsbuild/model/descriptor.dart';

import 'config.dart';
import 'registry.dart';
import 'repository.dart';

abstract class DsBuildApi {
  final Config config;
  final Repository repository;
  final Registry registry;

  DsBuildApi(this.config, this.repository, this.registry);

  List<String> verifyDescriptor() {
    List<String> errors = [];

    // Verify preprocessors
    for (StepDescriptor step in repository.descriptor.preprocessorSteps) {
      if (!registry.preprocessors.containsKey(step.type)) {
        errors.add("No preprocessor matching type '${step.type}'");
      }
    }

    // Verify readers
    for (InputDescriptor input in repository.descriptor.inputs) {
      if (!registry.readers.containsKey(input.format)) {
        errors.add("No reader matching type '${input.format}'");
      }
    }

    // Verify postprocessors
    for (OutputDescriptor output in repository.descriptor.outputs) {
      for (StepDescriptor step in output.steps) {
        if (!registry.postprocessors.containsKey(step.type)) {
          errors.add("No postprocessor matching type '${output.format}");
        }
      }
    }

    // Verify writers
    for (OutputDescriptor output in repository.descriptor.outputs) {
      if (!registry.writers.containsKey(output.format)) {
        errors.add("No writer matching type '${output.format}'");
      }
    }

    return errors;
  }

  Stream<InputDescriptor> fetchRequirements();
}
