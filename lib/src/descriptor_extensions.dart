import 'dart:io';

import 'package:logging/logging.dart';

import '../cache.dart';
import 'descriptor.dart';

final Logger _log = Logger('dsbuild/CollectPackedData');

/// Collect data for the steps.
extension CollectPackedDataExtension on Iterable<StepDescriptor> {
  /// Collects data for the steps from the cache and returns a new cache with the required data.
  ///
  /// The underlying data is immutable and is never copied.
  /// If [includeAll] is true then all data from the provided cache will be included.
  /// If [readFromFileystem] is true then the keys will be interpreted as filenames and loaded into the new cache if it does not already exist.
  /// If [gzip] is true then raw data will be gzipped.
  Future<PackedDataCache> collectPackedData(
      {PackedDataCache? cache,
      bool includeAll = false,
      bool readFromFilesystem = false,
      bool gzip = false}) async {
    PackedDataCache newCache = includeAll && cache != null
        ? PackedDataCache(existing: cache)
        : PackedDataCache();

    for (StepDescriptor step in this) {
      for (String key in step.pack) {
        /// Check the cache for existing data
        if (!includeAll && cache != null) {
          PackedData? data = cache[key];
          if (data != null) {
            newCache[key] = data;
            continue;
          }
        }

        /// Load from filesystem
        if (readFromFilesystem) {
          File file = File(key);
          if (await file.exists()) {
            newCache[key] = gzip
                ? GzipData(await file.readAsBytes())
                : RawData(await file.readAsBytes());
            continue;
          }
        }

        _log.info(
            "Unable to locate '$key' in cache. Transformers may choose to fail if this data is required.");
      }
    }

    return newCache;
  }
}
