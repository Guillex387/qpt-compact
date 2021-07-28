import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:qpt_compact/src/exceptions.dart';
import 'package:qpt_compact/src/utils.dart';
import 'package:qpt_compact/src/encoder.dart';

class FileCompactor {
  static String compress(String path, [String? outpath]) {
    var originFile = File(path).absolute;
    if (!originFile.existsSync())
      throw CompactorError('The input file doesn\' exists');
    final parentFolder = originFile.parent.path;
    final fileName = p.basename(originFile.path);
    final fileNameWE = p.withoutExtension(fileName); // without extension
    final destinationPath =
        (outpath == null) ? p.join(parentFolder, '$fileNameWE.pck') : outpath;
    var destinationFile = File(destinationPath).absolute;
    // Create the structure
    Uint8List originalContent = originFile.readAsBytesSync();
    try {
      Uint8List content = Compressor.encode(originalContent);
      int headerLength = jsonEncode({
        '$fileName': 'qwertyuiopasdfghjklñzxcv',
      }).length;
      final headerLengthB = toBytes(headerLength);
      var byteoffset = toBytes(8 + headerLength);
      var length = toBytes(content.length);
      String byteoffset_b64 = Base64Codec().encode(byteoffset);
      String length_b64 = Base64Codec().encode(length);
      final String location = byteoffset_b64 + length_b64;
      var header = jsonEncode({
        '$fileName': location,
      });
      final headerB = Utf8Codec().encode(header);
      // Save the structure in destination file
      if (!destinationFile.existsSync()) destinationFile.createSync();
      destinationFile.writeAsBytesSync(headerLengthB, mode: FileMode.append);
      destinationFile.writeAsBytesSync(headerB, mode: FileMode.append);
      destinationFile.writeAsBytesSync(content, mode: FileMode.append);
    } catch (_) {
      throw CompactorError('Error encoding \'$fileName\'');
    }
    return destinationFile.uri.toString();
  }
}
