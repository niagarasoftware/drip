import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  static final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  static bool _isOnline = false; // Global status

  static bool get isOnline => _isOnline; // Accessor
  static Stream<bool> get connectionStream => _connectionController.stream;

  static Future<void> initialize() async {
    // Initial check
    final initialResult = await _connectivity.checkConnectivity();
    _isOnline = initialResult != ConnectivityResult.none;
    _connectionController.add(_isOnline);

    // Listen to changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      _connectionController.add(_isOnline);
    });
  }

  static Future<bool> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static void dispose() {
    _connectionController.close();
  }
}