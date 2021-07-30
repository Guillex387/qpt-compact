import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:qpt_compact/src/exceptions.dart';
import 'package:qpt_compact/src/utils.dart';
import 'package:qpt_compact/src/encoder.dart';

bool _isFile(String path) =>
    Link(path).statSync().type == FileSystemEntityType.file;

File _defaultPath(Directory saveDir, [int? seed]) {
  int _seed = (seed == null) ? 0 : seed;
  String name = 'untitled$_seed.pck';
  var file = File(p.join(saveDir.path, name));
  if (file.existsSync()) return _defaultPath(saveDir, _seed + 1);
  file.createSync();
  return file;
}

int _calculateHeader(Map header) {
  Map recontructHeaderObj(Map header) {
    Map recontruction = {...header};
    recontruction.forEach((key, value) {
      if (value is String) {
        recontruction[key] =
            'qwertyuiopasdfghjklñzxcv'; // Simulate a location string for calculate the header length
      } else if (value is Map) {
        recontruction[key] = recontructHeaderObj(value);
      }
    });
    return recontruction;
  }

  Map obj = recontructHeaderObj(header);
  String codec = jsonEncode(obj);
  return codec.length;
}

class Compactor {
  static List _readPaths(List<String> paths, bool compress, int initalLength) {
    Map header = {};
    List<Uint8List> contents = [];
    for (var path in paths) {
      path = path.replaceAll('"', '');
      var isFile = _isFile(path);
      if (isFile) {
        var file = File(path);
        if (!file.existsSync())
          throw CompactorError('The input file \'$path\' doesn\'t exists');
        var rawData = file.readAsBytesSync();
        final data = compress ? Compressor.encode(rawData) : rawData;
        header[p.basename(path)] = (initalLength + contents.length).toString();
        contents.add(data);
      } else {
        var dir = Directory(path.replaceAll('"', ''));
        if (!dir.existsSync())
          throw CompactorError('The input folder \'$path\' doesn\'t exists');
        List<String> content =
            dir.listSync().map((systemElement) => systemElement.path).toList();
        var data = _readPaths(content, compress, contents.length);
        header[p.basename(path)] = data[0];
        contents.addAll(data[1] as List<Uint8List>);
      }
    }
    return [header, contents];
  }

  static int _replaceIndexed(
    Map header,
    List<Uint8List> contents,
    int initialLength,
  ) {
    var length = initialLength;
    header.forEach((key, value) {
      if (value is String) {
        final offset = length;
        final bytes = contents[int.parse(value)].length;
        final offsetB64 = Base64Codec().encode(Utils.toBytes(offset));
        final bytesB64 = Base64Codec().encode(Utils.toBytes(bytes));
        final location = offsetB64 + bytesB64;
        header[key] = location;
        length += bytes;
      } else if (value is Map) {
        length = _replaceIndexed(header[key], contents, length);
      }
    });
    return length;
  }

  static void _saveOutput(
    Uint8List headerLength,
    Uint8List header,
    List<Uint8List> contents,
    File destination,
  ) {
    destination.writeAsBytesSync(headerLength);
    destination.writeAsBytesSync(header, mode: FileMode.append);
    for (var content in contents) {
      destination.writeAsBytesSync(content, mode: FileMode.append);
    }
  }

  static String compress(List<String> paths,
      [String? outpath, bool? compress]) {
    // Create the structure
    bool _compress = (compress == null) ? true : compress;
    var data = _readPaths(paths, _compress, 0);
    Map header = data[0];
    header['compressed'] = _compress;
    final contents = data[1] as List<Uint8List>;
    final headerLength = _calculateHeader(header);
    final initalLength = 8 + headerLength;
    _replaceIndexed(header, contents, initalLength);
    final headerLengthB = Utils.toBytes(headerLength);
    final headerB = Utf8Encoder().convert(jsonEncode(header));
    // Save the structure
    var defaultSaveDir = Link(paths[0]).absolute.parent;
    var destinationFile = (outpath == null)
        ? _defaultPath(defaultSaveDir)
        : File(outpath).absolute;
    if (!destinationFile.existsSync()) destinationFile.createSync();
    _saveOutput(headerLengthB, headerB, contents, destinationFile);
    return destinationFile.uri.toString();
  }
}
