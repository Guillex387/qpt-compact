import 'dart:io';
import 'package:qpt_compact/qpt_compact.dart' as qpt_compact;
import 'package:colorize/colorize.dart' as colr;
import 'package:args/args.dart';

const helpMsg = 'type "compactor <-h | --help>" for the help message\n\n' +
    '"compactor <command> <options> <value>":\n\n' +
    'Commands:\n' +
    '\tcompact -> Compact the input file or folder indicated in the value\n' +
    '\t\toptions -> -o or --output <file>\n' +
    '\tdecompact -> Decompact the input file or folder indicated in the value';
const versionMsg = 'qpt-compact 1.0.0';

ArgParser createParser() {
  var parser = ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false);
  parser.addFlag('version', abbr: 'v', negatable: false);
  var compCommand = ArgParser();
  var dcompCommand = ArgParser();
  compCommand.addOption('output', abbr: 'o');
  parser.addCommand('compact', compCommand);
  parser.addCommand('decompact', dcompCommand);
  return parser;
}

void displaySuccess(String msg) {
  var displayStr = colr.Colorize(msg);
  displayStr.bold();
  displayStr.lightGreen();
  stdout.writeCharCode(13);
  stdout.writeln(displayStr);
}

void displayError(String msg) {
  var displayStr = colr.Colorize(msg);
  displayStr.bold();
  displayStr.red();
  stdout.writeCharCode(13);
  stderr.writeln(displayStr);
}

void main(List<String> arguments) async {
  var loader = qpt_compact.Loader();
  try {
    var parser = createParser();
    var results = parser.parse(arguments);
    if (results['help'] as bool) {
      print(helpMsg);
      exit(0);
    } else if (results['version'] as bool) {
      print(versionMsg);
      exit(0);
    }
    ArgResults? command = results.command;
    if (command == null || command.rest.length != 1) {
      displayError('Args error');
      exit(1);
    }
    bool compactCommand = (command.name == 'compact');
    var link = Link(command.rest[0].replaceAll('"', ''));
    var stopwatch = Stopwatch();
    bool file = link.statSync().type == FileSystemEntityType.file;
    stopwatch.start();
    await loader.start();
    String outpath;
    if (compactCommand) {
      String? output = command['output'];
      outpath = file
          ? qpt_compact.FileCompactor.compress(link.path, output)
          : qpt_compact.FolderCompactor.compress(link.path, output);
    } else {
      outpath = qpt_compact.Decompactor.decompress(link.path);
    }
    stopwatch.stop();
    double elapsed = stopwatch.elapsed.inMilliseconds / 1000;
    loader.kill();
    if (compactCommand) {
      displaySuccess(
          '${(file ? 'File' : 'Folder')} compressed at \'$outpath\' in ${elapsed}s');
    } else {
      displaySuccess('Decompressed at \'$outpath\' in ${elapsed}s');
    }
  } on qpt_compact.CompactorError catch (e) {
    loader.kill();
    displayError(e.message);
    exit(1);
  } on ArgParserException catch (_) {
    loader.kill();
    displayError('Args error');
    exit(1);
  } catch (_) {
    loader.kill();
    displayError('Unknow error');
    exit(1);
  }
}
