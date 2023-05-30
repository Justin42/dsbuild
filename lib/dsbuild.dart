/// Primary high-level interface. See [DsBuild]
library dsbuild;

export 'src/api.dart' show DsBuild;
export 'src/conversation.dart' show Conversation, MessageEnvelope;
export 'src/descriptor.dart'
    show DatasetDescriptor, InputDescriptor, OutputDescriptor, PassDescriptor;
export 'src/error.dart' show FileVerificationError;
