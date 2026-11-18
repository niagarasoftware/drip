import 'dart:async';

import 'package:flutter/material.dart';

class CountdownTimerWidget extends StatefulWidget {
  final Color fontColor;
  final double fontSize;
  final FontWeight fontWeight;
  final int initialSeconds;

  const CountdownTimerWidget({super.key, required this.initialSeconds, this.fontColor = Colors.black, this.fontSize = 12, this.fontWeight = FontWeight.bold});

  @override
  _CountdownTimerWidgetState createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late int secondsRemaining;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    secondsRemaining = widget.initialSeconds;
    startTimer();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    timer = Timer.periodic(oneSec, (Timer timer) {
      setState(() {
        if (secondsRemaining < 1) {
          timer.cancel();
        } else {
          secondsRemaining -= 1;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    int hours = secondsRemaining ~/ 3600;
    int minutes = (secondsRemaining % 3600) ~/ 60;
    int seconds = secondsRemaining % 60;

    return Center(
      child: Text(
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: TextStyle(color: widget.fontColor, fontSize: widget.fontSize, fontWeight: widget.fontWeight),
      ),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}