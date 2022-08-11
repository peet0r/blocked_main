import 'dart:io';

import 'package:blocked_main/watchdog.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  WatchDogManager wdManager = WatchDogManager()..init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Blocked Main Thread'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _status = "Responsive";
  double _size = 26.0;

  @override
  void initState() {
    super.initState();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _blockingFunction() {
    setState(() {
      _counter = 0;
      _status = "Unresponsive";
    });
    Future.delayed(const Duration(milliseconds: 10)).then((value) {
      List<int>.generate(
        pow(2, _size).toInt(),
        (index) => Random().nextInt(1 << 32),
      );
      setState(() {
        _status = "Responsive";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Main Thead Status: $_status',
            style: Theme.of(context).textTheme.subtitle2,
          ),
          Text(
            '$_counter',
            style: Theme.of(context).textTheme.headline1,
          ),
          Text(
            'counter gets reset when Block Main is called',
            style: Theme.of(context).textTheme.caption,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 48.0),
            child: Text(
              'Main thread workload factor: ${_size.round()}',
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
          Text(
            'tune this for your machine. O(n)=2^n',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48.0, right: 48.0),
            child: Slider(
                value: _size,
                min: 20,
                max: 32,
                divisions: 12,
                label: _size.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _size = value;
                  });
                }),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _blockingFunction,
                  child: const Text('Block Main'),
                ),
                OutlinedButton(
                  onPressed: _incrementCounter,
                  child: const Text('Increment Counter'),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let\'s block the main thread:',
                style: Theme.of(context).textTheme.subtitle2,
              ),
              Text(
                '1. Click the Increment Counter button a few times, note the behavior.',
                style: Theme.of(context).textTheme.caption,
              ),
              Text(
                '2. Click Block Main to put application into unresponsive state.',
                style: Theme.of(context).textTheme.caption,
              ),
              Text(
                '3. While in unresponsive state, click the Increment Counter button N times.',
                style: Theme.of(context).textTheme.caption,
              ),
              Text(
                '4. Once main becomes responsive, note that count is ~= N, i.e. input events are queued.',
                style: Theme.of(context).textTheme.caption,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Text(
              'For even more watchdog fun: Open your console. Woof Woof',
              style: Theme.of(context).textTheme.subtitle2,
            ),
          ),
        ],
      ),
    );
  }
}
