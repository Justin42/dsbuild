import 'dart:async';

import 'config.dart';
import 'model/conversation.dart';
import 'model/descriptor.dart';
import 'registry.dart';
import 'repository.dart';

abstract class DsBuildApi {
  final Config config;
  final Repository repository;
  final Registry registry;

  DsBuildApi(this.config, this.repository, this.registry);

  /// Verify the descriptor is valid and all required transformers are registered.
  List<String> verifyDescriptor();

  /// Fetch all requirements.
  /// yields an InputDescriptor for each newly satisfied dependency.
  Stream<InputDescriptor> fetchRequirements();

  /// Perform the specified transformation steps.
  Stream<MessageEnvelope> transform(
      Stream<MessageEnvelope> messages, List<StepDescriptor> steps);

  /// Perform the postprocessing steps defined in the OutputDescriptor
  Stream<Conversation> postProcess(
      Stream<Conversation> conversations, OutputDescriptor output);

  /// Utility function to concatenate multiple MessageEnvelope streams.
  // This should probably be replaced by a StreamGroup or something.
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

  /// Transform each input according to it's InputDescriptor.
  /// The transformation output is concatenated, in the order of input, into a single Conversation stream.
  Stream<Conversation> transformAll() async* {
    List<Stream<MessageEnvelope>> pending = [];
    for (InputDescriptor inputDescriptor in repository.descriptor.inputs) {
      Stream<MessageEnvelope> pipeline =
          transform(read(inputDescriptor), inputDescriptor.steps);
      pending.add(pipeline);
    }
    yield* concatenateMessages(pending);
  }

  /// Write the output conversation stream to the specified output.
  /// Stream elements are unaltered.
  Stream<Conversation> write(
          Stream<Conversation> conversations, OutputDescriptor output) =>
      registry.writers[output.format]!
          .call({}).write(conversations, output.path);

  /// Read the input specified by the InputDescriptor.
  /// yields MessageEnvelope for each message.
  Stream<MessageEnvelope> read(InputDescriptor inputDescriptor) =>
      registry.readers[inputDescriptor.format]!
          .call({}).read(inputDescriptor.path);

  /// Write the conversation stream to all outputs.
  /// yields OutputDescriptor for each output.
  Stream<OutputDescriptor> writeAll(Stream<Conversation> conversations) async* {
    for (OutputDescriptor descriptor in repository.descriptor.outputs) {
      await write(conversations, descriptor).drain();
      yield descriptor;
    }
  }
}
