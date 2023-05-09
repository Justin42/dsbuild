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
}
