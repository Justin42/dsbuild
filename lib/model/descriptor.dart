import 'package:yaml/yaml.dart';

class DatasetDescriptor {
  final String name;
  final String description;
  final bool generateReadme;
  final List<InputDescriptor> inputs;
  final List<OutputDescriptor> outputs;

  // Collects preprocessor step descriptors from inputs.
  List<StepDescriptor> get preprocessorSteps {
    List<StepDescriptor> steps = [];
    for (InputDescriptor input in inputs) {
      steps.addAll(input.steps);
    }
    return steps;
  }

  const DatasetDescriptor(
      {this.name = 'default',
      this.description = 'No description',
      this.generateReadme = true,
      this.inputs = const [],
      this.outputs = const []});

  DatasetDescriptor.fromYaml(YamlMap data)
      : name = data['name'],
        description = data['description'],
        generateReadme = data['build']['generateReadme'],
        inputs = [
          for (var input in data['inputs']) InputDescriptor.fromYaml(input)
        ],
        outputs = [] {
    for (var input in data['inputs']) {
      inputs.add(InputDescriptor.fromYaml(input));
    }
  }
}

class InputDescriptor {
  final String path;
  final String description;
  final String source;
  final String format;
  final List<StepDescriptor> steps;

  const InputDescriptor(
      this.path, this.description, this.source, this.format, this.steps);

  InputDescriptor.fromYaml(YamlMap data)
      : path = data['path'],
        description = data['description'],
        source = data['source'],
        format = data['format'],
        steps = [
          if (data['steps'] != null)
            for (var step in data['steps'])
              if (step != null) StepDescriptor.fromYaml(step)
        ];
}

class OutputDescriptor {
  final Uri uri;
  final String description;
  final String format;
  final List<StepDescriptor> steps;

  OutputDescriptor(this.uri, this.description, this.format, this.steps);
}

class StepDescriptor {
  final String type;
  final String description;
  final Map<String, dynamic> config;

  const StepDescriptor(this.type, this.description, this.config);

  StepDescriptor.fromYaml(YamlMap data)
      : type = data['type'],
        description = data['description'],
        config = {if (data['config'] != null) ...data['config']};
}
