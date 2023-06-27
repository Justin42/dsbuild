import 'package:meta/meta.dart';

/// Configuration for stats tracking
@immutable
class StatsConfig {
  /// Enable vocabulary stats. Significant resource cost for large datasets.
  final bool enableVocabulary = true;

  /// Enable message Id's in stats output
  final bool includeMessageIds = true;

  /// Create a new instance
  const StatsConfig();
}
