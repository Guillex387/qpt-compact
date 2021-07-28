import 'dart:typed_data';
import 'package:archive/archive.dart' as archive;

class Compressor {
  static final _encoder = archive.BZip2Encoder();
  static final _decoder = archive.BZip2Decoder();

  static Uint8List encode(Uint8List bytes) {
    final data = _encoder.encode(bytes);
    return Uint8List.fromList(data);
  }

  static Uint8List decode(Uint8List bytes) {
    final data = _decoder.decodeBytes(bytes);
    return Uint8List.fromList(data);
  }
}
