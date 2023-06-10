### Dataset Preparation for LM Training

Designed to help users clean and prepare their datasets for use in language model (LM) training. It is
built using the Dart programming language and utilizes YAML configuration to describe the steps used to construct the
dataset. The goal is to enable easy review, replication, and iteration upon the dataset, making it easier for users to
train high-quality language models.

*This package can be used either as a standalone tool, or as a library to introduce complex build steps.*

Key Features:

- Simple multithreaded transformation pipeline using Dart's `StreamTransformer`
- YAML configuration for easy review, replication, and iteration.
- Common transformers for pruning or stripping messages.

Upcoming Features:

- Remote workers via gRPC API.
- Better handling for progress and artifacts.

For installing the tool from source see [here](https://github.com/Justin42/dsbuild/wiki/Install).
