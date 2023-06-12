import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// A simple in-memory compressible binary datastore.
class PackedDataCache {
  final HashMap<String, PackedData> _data;

  /// Create a new instance.
  PackedDataCache({Map<String, PackedData>? existing})
      : _data = existing != null ? HashMap.of(existing) : HashMap();

  /// Add data to the cache
  void add(String key, PackedData data) {
    _data[key] = data;
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
class RawData extends PackedData {
  /// Create a new instance
  const RawData(Uint8List raw) : super(const PackedDataHeader('RawData'), raw);

  /// Gzip the data
  List<int> deflate() {
    return gzip.encoder.convert(data);
  }

  /// Convert the data to [GzipData] instance
  GzipData toGzipData() {
    return GzipData(Uint8List.fromList(deflate()));
  }
}

/// Raw binary data packed with gzip
class GzipData extends PackedData {
  /// Create a new instance
  const GzipData(Uint8List gzipped)
      : super(const PackedDataHeader('GzipData'), gzipped);

  /// Inflate the data
  List<int> inflate() {
    return gzip.decoder.convert(data);
  }

  /// Convert the data to a [RawData] instance
  RawData toRawData() {
    return RawData(Uint8List.fromList(inflate()));
  }
}
