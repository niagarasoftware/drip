import 'dart:async';

import 'package:flutter/cupertino.dart';

class DurationNotifier extends ChangeNotifier {
  ValueNotifier<String> leftDurationOrFlow = ValueNotifier<String>('00:00:00');
  ValueNotifier<String> onDelayLeft = ValueNotifier<String>('00:00:00');

  void updateDuration(String newDuration) {
    leftDurationOrFlow.value = newDuration;
  }

  void updateOnDelayTime(String onDelayTime) {
    onDelayLeft.value = onDelayTime;
  }
}

class DecreaseDurationNotifier extends ChangeNotifier {
  late Duration _duration;
  late Timer _timer;

  DecreaseDurationNotifier(String timeLeft) {
    _duration = _parseTime(timeLeft);
    _startTimer();
  }

  String get onDelayLeft => _formatTime(_duration);

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (_duration.inSeconds > 0) {
          _duration -= const Duration(seconds: 1);
          notifyListeners();
        } else {
          _timer.cancel();
          notifyListeners();
        }
      },
    );
  }

  Duration _parseTime(String time) {
    final parts = time.split(':');

    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
  }

  String _formatTime(Duration duration) {
    return "${duration.inHours.toString().padLeft(2, '0')}:"
        "${(duration.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

/*class DecreaseDurationNotifier extends ChangeNotifier {
  late Duration _duration;
  late Timer _timer;

  DecreaseDurationNotifier(String timeLeft) {
    _duration = _parseTime(timeLeft);
    _startTimer();
  }

  String get onDelayLeft => _formatTime(_duration);

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_duration.inSeconds > 0) {
        _duration -= const Duration(seconds: 1);
        notifyListeners();
      } else {
        _timer.cancel();
        notifyListeners();
      }
    });
  }

  Duration _parseTime(String time) {
    List<String> parts = time.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
  }

  String _formatTime(Duration duration) {
    return "${duration.inHours.toString().padLeft(2, '0')}:"
        "${(duration.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}*/

class IncreaseDurationNotifier extends ChangeNotifier {
  late Duration _duration;
  late Timer _timer;

  late bool _isTimeFormat;
  double _liters = 0.0;
  double _setLiters = 0.0;
  double _flowRate = 0.0;

  String get onCompletedDrQ =>
      _isTimeFormat ? _formatTime(_duration) : _liters.toStringAsFixed(2);

  IncreaseDurationNotifier(String setValve, String completedValve, double flowRate) {
    _isTimeFormat = _checkIsTimeFormat(completedValve);
    _flowRate = flowRate;

    if (_isTimeFormat) {
      _duration = _parseTime(completedValve);
    } else {
      _liters = double.tryParse(completedValve) ?? 0.0;
      _setLiters = double.tryParse(setValve.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimeFormat) {
        _duration += const Duration(seconds: 1);
      } else {
        double flowRatePerSecond = _flowRate / 3600;
        _liters += flowRatePerSecond;

        if (_liters >= _setLiters) {
          _liters = _setLiters;
          _timer.cancel();
        }
      }

      notifyListeners();
    });
  }

  bool _checkIsTimeFormat(String value) {
    return value.contains(':');
  }

  Duration _parseTime(String time) {
    List<String> parts = time.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
  }

  String _formatTime(Duration duration) {
    return "${duration.inHours.toString().padLeft(2, '0')}:"
        "${(duration.inMinutes % 60).toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}