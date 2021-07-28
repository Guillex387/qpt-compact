import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:qpt_compact/src/encoder.dart';
import 'package:qpt_compact/src/exceptions.dart';
import 'package:qpt_compact/src/utils.dart';

int _calculateHeader(Map header) {
  Map recontructHeaderObj(Map header) {
    Map recontruction = {...header};
    recontruction.forEach((key, value) {
      if (value is String) {
        recontruction[key] =
            'qwertyuiopasdfghjklñzxcv'; // Simulate a location string for calculate the header length
      } else {
        recontruction[key] = recontructHeaderObj(value as Map);
      }
    });
    return recontruction;
  }

  Map obj = recontructHeaderObj(header);
  String codec = jsonEncode(obj);
  return codec.length;
}

int _replaceIndexed(Map map, List<Uint8List> list, int initalLength) {
  var length = initalLength;
  map.forEach((key, value) {
    if (value is String) {
      final bytes = list[int.parse(value)].length;
      final offset = length;
      final bytesB64 = Base64Codec().encode(toBytes(bytes));
      final offsetB64 = Base64Codec().encode(toBytes(offset));
      final location = offsetB64 + bytesB64;
      map[key] = location;
      length += bytes;
    } else {
      length = _replaceIndexed(map[key], list, length);
    }
  });
  return length;
}

bool _isFile(String path) {
  var link = Link(path);
  return link.statSync().type == FileSystemEntityType.file;
}

class FolderCompactor {
  static List _readFolder(Directory folder, [int count = 0]) {
    Map map = {};
    List<Uint8List> contents = [];
    for (var children in folder.listSync()) {
      if (_isFile(children.path)) {
        var file = File(children.path);
        map[p.basename(file.path)] = '${count + contents.length}';
        final compData = Compressor.encode(file.readAsBytesSync());
        contents.add(compData);
      } else {
        final dir = _readFolder(
          Directory(children.path),
          contents.length,
        );
        map[p.basename(children.path)] = dir[1];
        contents.addAll(dir[0]);
      }
    }
    return [contents, map];
  }

  static String compress(String path, [String? outpath]) {
    var folder = Directory(path).absolute;
    if (!folder.existsSync())
      throw CompactorError('The input folder doesn\'t exists');
    var folderName = p.basename(folder.path);
    var parentFolder = folder.parent.path;
    final destinationPath =
        (outpath == null) ? p.join(parentFolder, '$folderName.pck') : outpath;
    // Create the structure of file
    var data = _readFolder(folder);
    Map headerObj = {
      '$folderName': data[1],
    };
    List<Uint8List> contents = data[0];
    final headerLength = _calculateHeader(headerObj);
    final initalLength = 8 + headerLength;
    _replaceIndexed(headerObj, contents, initalLength);
    // Save the structure in the file
    var destinationFile = File(destinationPath).absolute;
    if (!destinationFile.existsSync()) destinationFile.createSync();
    final headerLengthB = toBytes(headerLength);
    var headerStr = jsonEncode(headerObj);
    final headerB = Utf8Encoder().convert(headerStr);
    destinationFile.writeAsBytesSync(headerLengthB, mode: FileMode.append);
    destinationFile.writeAsBytesSync(headerB, mode: FileMode.append);
    for (var bytes in contents) {
      destinationFile.writeAsBytesSync(bytes, mode: FileMode.append);
    }
    return destinationFile.uri.toString();
  }
}
