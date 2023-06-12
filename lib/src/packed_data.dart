import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final Logger _log = Logger('dsbuild/PackedDataCache');

/// A simple in-memory compressible binary datastore.
class PackedDataCache {
  /// The backing datastore
  final HashMap<String, PackedData> _data;

  /// Total bytes for the binary data stored in the cache.
  ///
  /// This does not include header data or overhead from the backing datastore.
  int get totalBytes {
    int count = 0;
    for (PackedData data in _data.values) {
      count += data.data.length;
    }
    return count;
  }

  /// Create a new instance.
  PackedDataCache({PackedDataCache? existing})
      : _data = existing != null ? HashMap.of(existing._data) : HashMap();

  /// Whether this map contains the given [key].
  bool containsKey(String key) => _data.containsKey(key);

  /// Associates the key with the given value.
  void operator []=(String key, PackedData data) => _data[key] = data;

  /// The value for the given key, or null if key is not in the map.
  PackedData? operator [](String? key) => _data[key];

  /// Adds all key/value pairs of [other] to this map.
  void addAll(PackedDataCache other) {
    _data.addAll(other._data);
  }

  @override
  String toString() {
    return _data.entries
        .map((MapEntry<String, PackedData> entry) =>
            (entry.key, entry.value.data.length))
        .toList(growable: false)
        .toString();
  }
}

/// A mixin for deflatable types
abstract mixin class Deflatable {
  /// Deflate the data
  List<int> deflate();

  /// Convert the data to [GzipData] instance
  GzipData toGzipData() {
    return GzipData(Uint8List.fromList(deflate()));
  }
}

/// A mixin for inflatable types
abstract mixin class Inflatable {
  /// Inflate the data
  List<int> inflate();

  /// Convert the data to a [RawData] instance
  RawData toRawData() {
    return RawData(Uint8List.fromList(inflate()));
  }
}

/// Header for packed data.
@immutable
class PackedDataHeader {
  /// Data type
  final String type;

  /// Whether the data is gzipped.
  bool get gzipped => type == 'GzipData';

  /// Whether the data is raw.
  bool get isRaw => type == 'RawData';

  /// Create a new instance
  const PackedDataHeader(this.type);
}

/// Packed data
@immutable
abstract class PackedData {
  /// Header data
  final PackedDataHeader header;

  /// Raw data
  final Uint8List data;

  /// Create a new instance with the provided header and data.
  const PackedData(this.header, this.data);
}

/// Raw binary data
class RawData extends PackedData with Deflatable {
  /// Create a new instance
  const RawData(Uint8List raw) : super(const PackedDataHeader('RawData'), raw);

  /// Gzip the data
  @override
  List<int> deflate() {
    return gzip.encoder.convert(data);
  }
}

/// Raw binary data packed with gzip
class GzipData extends PackedData with Inflatable {
  /// Create a new instance
  const GzipData(Uint8List gzipped)
      : super(const PackedDataHeader('GzipData'), gzipped);

  /// Inflate the data
  @override
  List<int> inflate() {
    return gzip.decoder.convert(data);
  }
}
