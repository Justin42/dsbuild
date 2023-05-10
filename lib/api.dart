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

  Stream<MessageEnvelope> transform(
      Stream<MessageEnvelope> messages, List<StepDescriptor> steps);

  Stream<Conversation> postProcess(
      Stream<Conversation> conversations, OutputDescriptor output);

  Stream<Conversation> concatenateMessages(
      List<Stream<MessageEnvelope>> data) async* {
    for (Stream<MessageEnvelope> pipeline in data) {
      final List<Message> convoMessages = [];
      StreamIterator<MessageEnvelope> messages = StreamIterator(pipeline);
      await messages.moveNext();
      convoMessages.add(Message(messages.current.from, messages.current.value));
      int convoId = messages.current.conversation;

      while (await messages.moveNext()) {
        // Start new convo
        if (messages.current.conversation != convoId) {
          yield Conversation(messages: convoMessages);
          convoId = messages.current.conversation;
          convoMessages.clear();
        }
        // Add message to convo
        else {
          convoMessages
              .add(Message(messages.current.from, messages.current.value));
        }
      }
    }
  }

  Stream<Conversation> transformAll() async* {
    List<Stream<MessageEnvelope>> pending = [];
    for (InputDescriptor inputDescriptor in repository.descriptor.inputs) {
      Stream<MessageEnvelope> pipeline =
          transform(read(inputDescriptor), inputDescriptor.steps);
      pending.add(pipeline);
    }
    yield* concatenateMessages(pending);
  }

  Stream<Conversation> write(
          Stream<Conversation> conversations, OutputDescriptor output) =>
      registry.writers[output.format]!
          .call({}).write(conversations, output.path);

  Stream<MessageEnvelope> read(InputDescriptor inputDescriptor) =>
      registry.readers[inputDescriptor.format]!
          .call({}).read(inputDescriptor.path);

  Stream<OutputDescriptor> writeAll(Stream<Conversation> conversations) async* {
    for (OutputDescriptor descriptor in repository.descriptor.outputs) {
      await write(conversations, descriptor).drain();
      yield descriptor;
    }
  }
}
