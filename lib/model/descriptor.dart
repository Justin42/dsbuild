import 'package:yaml/yaml.dart';

class DatasetDescriptor {
  final String name;
  final String description;
  final bool generateReadme;
  final bool generateHashes;
  final bool verifyHashes;
  final int parallel;
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
      this.generateHashes = true,
      this.verifyHashes = true,
      this.parallel = 4,
      this.inputs = const [],
      this.outputs = const []});

  DatasetDescriptor.fromYaml(YamlMap data)
      : name = data['name'] ?? 'default',
        description = data['description'] ?? 'No description',
        generateReadme = data['build']['generateReadme'] ?? true,
        generateHashes = data['build']['generateHashes'] ?? true,
        verifyHashes = data['build']['verifyHashes'] ?? true,
        parallel = data['build']['parallel'] ?? 4,
        inputs = [
          for (var input in data['input']) InputDescriptor.fromYaml(input)
        ],
        outputs = [
          for (var output in data['output']) OutputDescriptor.fromYaml(output)
        ];
}

class InputDescriptor {
  final String path;
  final String description;
  final Uri source;
  final String? hash;
  final String format;
  final List<StepDescriptor> steps;

  const InputDescriptor(
      this.path, this.description, this.source, this.format, this.steps,
      {this.hash});

  InputDescriptor.fromYaml(YamlMap data)
      : path = data['path'],
        description = data['description'],
        source = Uri.parse(data['source']),
        hash = data['sha512'],
        format = data['format'],
        steps = [
          if (data['steps'] != null)
            for (var step in data['steps'])
              if (step != null) StepDescriptor.fromYaml(step)
        ];

  InputDescriptor copyWith(
      {String? path,
      String? description,
      Uri? source,
      String? hash,
      String? format,
      List<StepDescriptor>? steps}) {
    return InputDescriptor(path ?? this.path, description ?? this.description,
        source ?? this.source, format ?? this.format, steps ?? this.steps,
        hash: hash ?? this.hash);
  }
}

class OutputDescriptor {
  final String path;
  final String description;
  final String format;
  final List<StepDescriptor> steps;

  OutputDescriptor(this.path, this.description, this.format, this.steps);

  OutputDescriptor.fromYaml(YamlMap data)
      : path = data['path'],
        description = data['description'] ?? 'Output Data',
        format = data['format'],
        steps = [
          if (data['steps'] != null)
            for (var step in data['steps'])
              if (step != null) StepDescriptor.fromYaml(step)
        ];
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
