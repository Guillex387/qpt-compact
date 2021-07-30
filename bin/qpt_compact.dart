import 'dart:io';
import 'package:qpt_compact/qpt_compact.dart' as qpt_compact;
import 'package:colorize/colorize.dart' as colr;
import 'package:args/args.dart';

const helpMsg = 'type "compactor <-h | --help>" for the help message\n\n' +
    '"compactor <command> <options> <values>":\n\n' +
    'Commands:\n' +
    '\tcompact -> Compact the input files and folders indicated in the values\n' +
    '\t\toptions -> -o or --output <file> and --compress or --no-compress\n' +
    '\tdecompact -> Decompact the input files and folders indicated in the values\n' +
    '\t\toptions -> -o or --output <folder>';

const versionMsg = 'qpt-compact 1.1.0';

ArgParser createParser() {
  var parser = ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false);
  parser.addFlag('version', abbr: 'v', negatable: false);
  var compCommand = ArgParser();
  var dcompCommand = ArgParser();
  compCommand.addFlag('compress', defaultsTo: true);
  compCommand.addOption('output', abbr: 'o');
  dcompCommand.addOption('output', abbr: 'o');
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
  if (arguments.length == 0) {
    stdout.writeln(helpMsg);
    exit(1);
  }
  var loader = qpt_compact.Utils.Loader();
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
    if (command == null || command.rest.length == 0) {
      displayError('Args error');
      exit(1);
    }
    bool compactCommand = (command.name == 'compact');
    var link = Link(command.rest[0].replaceAll('"', '')).absolute;
    var stopwatch = Stopwatch();
    stopwatch.start();
    await loader.start();
    String? output = command['output'];
    String outpath;
    if (compactCommand) {
      bool? compress = command['compress'];
      outpath = qpt_compact.Compactor.compress(command.rest, output, compress);
    } else {
      outpath = qpt_compact.Decompactor.decompress(link.path, output);
    }
    stopwatch.stop();
    double elapsed = stopwatch.elapsed.inMilliseconds / 1000;
    await loader.kill();
    displaySuccess(
      '${(compactCommand ? 'Compressed' : 'Decompressed')} at \'$outpath\' in ${elapsed}s',
    );
  } on qpt_compact.CompactorError catch (e) {
    await loader.kill();
    displayError(e.message);
    exit(1);
  } on ArgParserException catch (_) {
    await loader.kill();
    displayError('Args error');
    exit(1);
  } catch (_) {
    await loader.kill();
    displayError('Unknow error');
    exit(1);
  }
}
