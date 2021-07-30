import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:isolate';
import 'package:colorize/colorize.dart' as colr;

class _Loader {
  static Future<void> _process(Stopwatch timer) async {
    timer.start();
    const slashes = ['-', '\\', '|', '/'];
    int slash = 0;
    while (true) {
      if (slash == 4) slash = 0;
      double drawTime = timer.elapsed.inMilliseconds / 1000;
      var msg = colr.Colorize('Processing... ${slashes[slash]} $drawTime');
      msg.bold();
      msg.lightBlue();
      if (!timer.isRunning) return;
      stdout.write(msg);
      await Future.delayed(Duration(milliseconds: 15));
      slash++;
      stdout.writeCharCode(13);
    }
  }

  Isolate? _isolate = null;
  Stopwatch _timer = Stopwatch();

  Future<void> start() async {
    _isolate = await Isolate.spawn(_process, _timer);
  }

  Future<void> kill() async {
    if (_isolate != null) {
      _timer.stop();
      _timer.reset();
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      // Wait time for terminate the execution of the isolate
      await Future.delayed(Duration(milliseconds: 50));
    }
  }
}

class Utils {
  static Uint8List toBytes(int n) =>
      Uint8List(8)..buffer.asByteData().setUint64(0, n);
  static int fromBytes(Uint8List bytes) =>
      bytes.buffer.asByteData().getUint64(0);

  static Uint8List readFile(File file, int offset, int length) {
    var controller = file.openSync(mode: FileMode.read);
    controller.setPositionSync(offset);
    final data = controller.readSync(length);
    controller.closeSync();
    return data;
  }

  static _Loader Loader() => _Loader();
}
