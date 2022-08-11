import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';

const String enableFlag = 'WD_WATCHDOG_ENABLED';
const String warningThresholdVAR = 'WD_WARNING_THRESHOLD';
const String errorThresholdVAR = 'WD_ERROR_THRESHOLD';
const String deadlockThresholdVAR = 'WD_DEADLOCK_THRESHOLD';
const double defaultWarningThreshold = 20.0;
const double defaultErrorThreshold = 120.0;
const int defaultDeadlockThreshold = 5;

final log = Logger('Watchdog');

class WatchDogManager {
  WatchDogManager();

  late Isolate isolate;
  late ReceivePort receivePort;
  late SendPort sendPort;
  late Stopwatch isolateTimer;
  late Ticker _ticker;

  Future<void> init() async {
    if (Platform.environment.containsKey(enableFlag)) {
      // Setup
      _ticker = Ticker((onTick) {
        sendMsg();
      });
      isolateTimer = Stopwatch()..start();
      receivePort = ReceivePort();

      await spawnNewIsolate().then((value) {
        _start();
      });

      // // ignore: avoid_dynamic_calls
      receivePort.listen((dynamic message) {
        if (message is SendPort) {
          sendPort = message;
        } else if (message is String) {
          log.info(message);
        }
      });
    }
  }

  Future<void> spawnNewIsolate() async {
    try {
      isolate = await Isolate.spawn(_watchdogService, receivePort.sendPort);
    } on Exception catch (e) {
      log.shout('Error: $e');
    }
  }

  static Future<void> _watchdogService(SendPort p) async {
    double warningThreshold = defaultWarningThreshold;
    double errorThreshold = defaultErrorThreshold;
    int deadlockThreshold = defaultDeadlockThreshold;
    String logfilePath = '${Directory.systemTemp.path}/watchdog_logs.txt';

    // Get settings from env
    if (Platform.environment.containsKey(warningThresholdVAR)) {
      warningThreshold =
          double.tryParse(Platform.environment[warningThresholdVAR]!) ??
              defaultWarningThreshold;
    }
    if (Platform.environment.containsKey(errorThresholdVAR)) {
      errorThreshold =
          double.tryParse(Platform.environment[errorThresholdVAR]!) ??
              errorThreshold;
    }
    if (Platform.environment.containsKey(deadlockThresholdVAR)) {
      deadlockThreshold =
          int.parse(Platform.environment[deadlockThresholdVAR]!);
    }
    print('Saving frame stats to: $logfilePath');
    final stats = StatsProvider();
    final commandPort = ReceivePort();
    p
      ..send(commandPort.sendPort)
      ..send(
        'Started watchdog isolate with wThreshold: $warningThreshold, eThreshold: $errorThreshold',
      );

    var timer = Timer(Duration(seconds: deadlockThreshold), () {
      print('Main thread is deadlocked....aborting');
      throw 'oh no!';
    });
    final frameTimer = Stopwatch()..start();
    commandPort.listen((dynamic message) {
      if (message is Duration) {
        timer.cancel();
        frameTimer.stop();
        if (frameTimer.elapsedMilliseconds > errorThreshold) {
          p.send(
            'Error: Frametime exceded $errorThreshold: ${frameTimer.elapsedMilliseconds}',
          );
        } else if (frameTimer.elapsedMilliseconds > warningThreshold) {
          p.send('Warning: Slow frame ${frameTimer.elapsedMilliseconds}');
        }
        stats.processFrame(message, frameTimer.elapsedMilliseconds);
        File(logfilePath).writeAsStringSync(stats.getStats());
        frameTimer
          ..reset()
          ..start();
        timer = Timer(Duration(seconds: deadlockThreshold), () {
          print('Main thread is deadlocked....aborting');
          throw 'oh no!';
        });
      }
    });

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    p.send('Watchdog Listening on: ${server.address.host}:${server.port}');
    await server.forEach((HttpRequest request) {
      request.response.write(stats.getStats());
      request.response.close();
    });
  }

  void _start() {
    _ticker.start();
  }

  void _stop() {
    _ticker.stop();
  }

  void sendMsg() {
    sendPort.send(isolateTimer.elapsed);
  }

  void dispose() {
    if (Platform.environment.containsKey(enableFlag)) {
      receivePort.close();
      isolate.kill();
      _ticker.dispose();
    }
  }
}

class StatsProvider {
  StatsProvider();
  late Duration _isolateTime;
  var _frameCount = 0;
  var _mean = 0.0;
  var _rollingSum = 0;
  var _rollingSumSum = 0.0;
  var _stdDiv = 0.0;
  var _worst = 0;

  void processFrame(Duration isolateTime, int frame) {
    _isolateTime = isolateTime;
    _frameCount++;
    _worst = (frame > _worst) ? frame : _worst;
    _rollingSum += frame;
    _mean = _rollingSum.toDouble() / _frameCount.toDouble();
    _rollingSumSum += pow(frame - _mean, 2.0) as double;
    _stdDiv = sqrt(_rollingSumSum / _frameCount);
  }

  String getStats() {
    return '''
    Timestamp  : ${_isolateTime.toString()}
    FrameCount : $_frameCount
    Mean       : $_mean
    StdDiv     : $_stdDiv
    Worst      : $_worst
    ''';
  }
}
