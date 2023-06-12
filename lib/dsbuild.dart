/// Primary high-level interface. See [DsBuild]
library dsbuild;

export 'src/api.dart' show DsBuild;
export 'src/conversation.dart' show Conversation, MessageEnvelope;
export 'src/descriptor.dart' show DatasetDescriptor, PassDescriptor;
export 'src/descriptor_extensions.dart' show CollectPackedDataExtension;
export 'src/error.dart' show FileVerificationError;
