import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:qpt_compact/src/encoder.dart';
import 'package:qpt_compact/src/exceptions.dart';
import 'package:qpt_compact/src/utils.dart';

Map _getHeader(File file) {
  int headerLength = fromBytes(readFile(file, 0, 8));
  Uint8List headerB = readFile(file, 8, headerLength);
  return jsonDecode(Utf8Decoder().convert(headerB));
}

List<int> _formatLocation(String location) {
  String offset_b64 = '';
  String length_b64 = '';
  for (int i = 0; i < 24; i++) {
    if (i < 12) {
      offset_b64 += location[i];
      continue;
    }
    length_b64 += location[i];
  }
  final offset = fromBytes(Base64Decoder().convert(offset_b64));
  final length = fromBytes(Base64Decoder().convert(length_b64));
  return [offset, length];
}

class Decompactor {
  static List _formatFile(File file, Map header, int initialIndex) {
    Map reconstruction = {...header};
    List<Uint8List> contents = [];
    reconstruction.forEach((key, value) {
      if (value is String) {
        var location = _formatLocation(value);
        var rawData = readFile(file, location[0], location[1]);
        try {
          final data = Compressor.decode(rawData);
          reconstruction[key] = '${initialIndex + contents.length}';
          contents.add(Uint8List.fromList(data));
        } catch (_) {
          throw CompactorError('Error decoding \'$key\'');
        }
      } else {
        var folderData = _formatFile(file, value, contents.length);
        reconstruction[key] = folderData[0];
        contents.addAll(folderData[1]);
      }
    });
    return [reconstruction, contents];
  }

  static void _constructTree(
    Map tree,
    List<Uint8List> contents,
    String parent,
  ) {
    tree.forEach((key, value) {
      var path = p.join(parent, key);
      if (value is String) {
        var file = File(path);
        if (!file.existsSync()) file.createSync();
        file.writeAsBytesSync(contents[int.parse(value)]);
      } else {
        var dir = Directory(path);
        if (!dir.existsSync()) dir.createSync();
        _constructTree(value, contents, path);
      }
    });
  }

  static String decompress(String path) {
    var file = File(path).absolute;
    if (!file.existsSync())
      throw CompactorError('The input file doesn\'t exists');
    String parentFolder = file.parent.path;
    Map header = _getHeader(file);
    final data = _formatFile(file, header, 0);
    _constructTree(data[0], data[1], parentFolder);
    return file.parent.uri.toString();
  }
}
