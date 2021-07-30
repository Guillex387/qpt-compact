import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:qpt_compact/src/encoder.dart';
import 'package:qpt_compact/src/exceptions.dart';
import 'package:qpt_compact/src/utils.dart';

Map _getHeader(File file) {
  int headerLength = Utils.fromBytes(Utils.readFile(file, 0, 8));
  Uint8List headerB = Utils.readFile(file, 8, headerLength);
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
  final offset = Utils.fromBytes(Base64Decoder().convert(offset_b64));
  final length = Utils.fromBytes(Base64Decoder().convert(length_b64));
  return [offset, length];
}

class Decompactor {
  static List _formatFile(
    File file,
    Map header,
    int initialIndex,
    bool compressed,
  ) {
    Map reconstruction = {...header};
    List<Uint8List> contents = [];
    reconstruction.forEach((key, value) {
      if (value is String) {
        var location = _formatLocation(value);
        var rawData = Utils.readFile(file, location[0], location[1]);
        try {
          final data = compressed ? Compressor.decode(rawData) : rawData;
          reconstruction[key] = '${initialIndex + contents.length}';
          contents.add(Uint8List.fromList(data));
        } catch (_) {
          throw CompactorError('Error decoding \'$key\'');
        }
      } else if (value is Map) {
        var folderData = _formatFile(file, value, contents.length, compressed);
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
      } else if (value is Map) {
        var dir = Directory(path);
        if (!dir.existsSync()) dir.createSync();
        _constructTree(value, contents, path);
      }
    });
  }

  static String decompress(String path, [String? folderOutput]) {
    var file = File(path.replaceAll('"', '')).absolute;
    if (!file.existsSync())
      throw CompactorError('The input file doesn\'t exists');
    Directory folderDestination = (folderOutput == null)
        ? file.parent.absolute
        : Directory(folderOutput.replaceAll('"', '')).absolute;
    if (!folderDestination.existsSync())
      throw CompactorError('The output folder doesn\'t exists');
    Map header = _getHeader(file);
    bool? compressed = header['compressed'];
    final data = _formatFile(
      file,
      header,
      0,
      (compressed == null) ? true : compressed,
    );
    _constructTree(data[0], data[1], folderDestination.path);
    return folderDestination.uri.toString();
  }
}
