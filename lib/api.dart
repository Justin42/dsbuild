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

  Future<Stream<MessageEnvelope>> transform(
      Stream<MessageEnvelope> messages, List<StepDescriptor> steps);

  Stream<Conversation> postProcess(
      Stream<Conversation> conversations, OutputDescriptor output);

  Stream<Conversation> concatenateMessages(
      List<Future<Stream<MessageEnvelope>>> data) async* {
    for (Future<Stream<MessageEnvelope>> pipeline in data) {
      final List<Message> convoMessages = [];
      StreamIterator<MessageEnvelope> messages = StreamIterator(await pipeline);
      await messages.moveNext();
      convoMessages.add(Message(messages.current.from, messages.current.value));
      int convoId = messages.current.conversation;

      while (await messages.moveNext()) {
        if (messages.current.conversation != convoId) {
          yield Conversation(messages: convoMessages);
          convoId = messages.current.conversation;
          convoMessages.clear();
        } else {
          convoMessages
              .add(Message(messages.current.from, messages.current.value));
        }
      }
    }
  }

  Future<Stream<Conversation>> transformAll() async {
    List<Future<Stream<MessageEnvelope>>> pending = [];
    for (InputDescriptor inputDescriptor in repository.descriptor.inputs) {
      Future<Stream<MessageEnvelope>> pipeline =
          transform(await read(inputDescriptor), inputDescriptor.steps);
      pending.add(pipeline);
    }
    return concatenateMessages(pending);
  }

  Stream<Conversation> write(
          Stream<Conversation> conversations, OutputDescriptor output) =>
      registry.writers[output.format]!
          .call({}).write(conversations, output.path);

  Future<Stream<MessageEnvelope>> read(InputDescriptor inputDescriptor) =>
      registry.readers[inputDescriptor.format]!
          .call({}).read(inputDescriptor.path);

  Stream<OutputDescriptor> writeAll(Stream<Conversation> conversations) async* {
    for (OutputDescriptor descriptor in repository.descriptor.outputs) {
      await write(conversations, descriptor).drain();
      yield descriptor;
    }
  }
}
