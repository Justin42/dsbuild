import 'dart:async';

import 'package:dsbuild/model/conversation.dart';
import 'package:dsbuild/model/descriptor.dart';

import 'config.dart';
import 'registry.dart';
import 'repository.dart';

abstract class DsBuildApi {
  final Config config;
  final Repository repository;
  final Registry registry;

  DsBuildApi(this.config, this.repository, this.registry);

  List<String> verifyDescriptor();

  Stream<InputDescriptor> fetchRequirements();

  Future<Stream<Conversation>> transform(InputDescriptor input);

  Stream<Conversation> transformAll() async* {
    for (InputDescriptor input in repository.descriptor.inputs) {
      yield* await transform(input);
    }
  }

  Stream<Conversation> postProcess(
      Stream<Conversation> conversations, OutputDescriptor output);
  Stream<Conversation> write(
          Stream<Conversation> conversations, OutputDescriptor output) =>
      registry.writers[output.format]!
          .call({}).write(conversations, output.path);

  Future<Stream<MessageEnvelope>> read(InputDescriptor inputDescriptor) =>
      registry.readers[inputDescriptor.format]!
          .call({}).read(inputDescriptor.path);

  Stream<OutputDescriptor> writeAll(List<Conversation> conversations) async* {
    for (OutputDescriptor output in repository.descriptor.outputs) {
      yield await write(conversations, output);
    }
  }
}
