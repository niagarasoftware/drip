import 'dart:async';
import 'package:flutter/material.dart';

class CounterStreamDemo extends StatefulWidget {
  @override
  _CounterStreamDemoState createState() => _CounterStreamDemoState();
}

class _CounterStreamDemoState extends State<CounterStreamDemo> {
  // Create a StreamController
  final StreamController<List<int>> _streamController = StreamController<List<int>>();
  int _counter = 0;

  @override
  void dispose() {
    _streamController.close(); // Close the stream to free resources
    super.dispose();
  }

  void _incrementCounter() {
    _counter++;
    _streamController.sink.add([_counter]);
  }

  @override
  Widget build(BuildContext context) {
    print('rebuild');
    return Scaffold(
      appBar: AppBar(title: Text('StreamBuilder')),
      body: Center(
        child: StreamBuilder<List<int>>(
          stream: _streamController.stream,
          initialData: [0],
          builder: (context, snapshot) {
            print('stream rebuild');
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Text(
                'Counter Value: ${snapshot.data}',
                style: TextStyle(fontSize: 24),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: Icon(Icons.add),
      ),
    );
  }
}
