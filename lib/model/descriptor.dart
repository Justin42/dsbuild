import 'package:yaml/yaml.dart';

class DatasetDescriptor {
  final String name;
  final String description;
  final bool generateReadme;
  final bool generateHashes;
  final bool verifyHashes;
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
      this.inputs = const [],
      this.outputs = const []});

  DatasetDescriptor.fromYaml(YamlMap data)
      : name = data['name'] ?? 'default',
        description = data['description'] ?? 'No description',
        generateReadme = data['build']?['generateReadme'] ?? false,
        generateHashes = data['build']?['generateHashes'] ?? true,
        verifyHashes = data['build']?['verifyHashes'] ?? true,
        inputs = [
          for (var input in data['input']) InputDescriptor.fromYaml(input)
        ],
        outputs = [
          for (var output in data['output']) OutputDescriptor.fromYaml(output)
        ];
}

class ReaderDescriptor {
  final String type;
  final Map<dynamic, dynamic> config;

  const ReaderDescriptor(this.type, this.config);

  ReaderDescriptor.fromYaml(YamlMap data)
      : type = data['type'],
        config = data['config'];
}

class WriterDescriptor {
  final String type;
  final Map<dynamic, dynamic> config;

  const WriterDescriptor(this.type, this.config);

  WriterDescriptor.fromYaml(YamlMap data)
      : type = data['type'],
        config = data['config'];
}

class InputDescriptor {
  final String path;
  final String description;
  final Uri? source;
  final String? hash;
  final ReaderDescriptor reader;
  final List<StepDescriptor> steps;

  const InputDescriptor(
      this.path, this.description, this.source, this.reader, this.steps,
      {this.hash});

  InputDescriptor.fromYaml(YamlMap data)
      : path = data['path'],
        description = data['description'],
        source = data['source'] != null ? Uri.parse(data['source']) : null,
        hash = data['sha512'],
        reader = (data['reader'] is String)
            ? ReaderDescriptor(data['reader'], {})
            : ReaderDescriptor.fromYaml(data['reader']),
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
      ReaderDescriptor? reader,
      List<StepDescriptor>? steps}) {
    return InputDescriptor(path ?? this.path, description ?? this.description,
        source ?? this.source, reader ?? this.reader, steps ?? this.steps,
        hash: hash ?? this.hash);
  }
}

class OutputDescriptor {
  final String path;
  final String description;
  final WriterDescriptor writer;
  final List<StepDescriptor> steps;

  OutputDescriptor(this.path, this.description, this.writer, this.steps);

  OutputDescriptor.fromYaml(YamlMap data)
      : path = data['path'],
        description = data['description'] ?? 'Output Data',
        writer = (data['writer'] is String)
            ? WriterDescriptor(data['writer'], {})
            : WriterDescriptor.fromYaml(data['writer']),
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
