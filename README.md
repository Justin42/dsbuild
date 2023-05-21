### Dataset Preparation Tool for LLM Training

This tool is designed to help users clean and prepare their datasets for use in language model (LM) training. It is
built using the Dart programming language and utilizes YAML configuration to describe the steps used to construct the
dataset. The goal is to enable easy review, replication, and iteration upon the dataset, making it easier for users to
train high-quality language models.

Key Features:

- YAML configuration for easy review, replication, and iteration.
- Common text transformers for pruning or stripping messages.

The processing pipeline is as follows:

**Reader -> Preprocessor -> Concatenate -> Postprocessor -> Writer**

The responsibilities for each component of the pipeline are as follows:

- **Readers**: Responsible for acquiring and formatting the data in a unified way to be fed to the preprocessors.
  Readers output a MessageEnvelope stream. Each MessageEnvelope contains information about its parent conversation, in
  addition to the message itself. This step *may* be run in parallel for each input.


- **Preprocessors**: Responsible for preparing the data for merge. Multiple preprocessors may be applied sequentially.
  Preprocessors receive and output a MessageEnvelope stream. This step runs sequentially after the Reader or a previous
  preprocessor, and runs in parallel for each input.


- **Concatenate**: Data output from preprocessors are collected in the order of their input. This step operates on a
  MessageEnvelope stream and outputs a Conversation stream. During this step, all conversations are fully stored in RAM.


- **Postprocessors**: Performs transformations on the final Conversation stream. This happens sequentially after the
  merge and is currently sequential for each Conversation. Unlike preprocessors, these receive the entire conversation
  in context. Receives and outputs a Conversation stream.


- **Writers**: Formats and outputs the final Conversation stream.
