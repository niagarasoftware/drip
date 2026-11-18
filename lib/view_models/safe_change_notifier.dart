import 'package:flutter/foundation.dart';

abstract class SafeChangeNotifier extends ChangeNotifier {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @protected
  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  bool get isDisposed => _isDisposed;
}