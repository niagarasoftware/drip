import 'package:flutter/foundation.dart';

class AppLog {
  AppLog._();

  static void log(dynamic message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void error(String message) {
    if (kDebugMode) {
      debugPrint("❌ ERROR: $message");
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint("⚠️ WARNING: $message");
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint("✅ SUCCESS: $message");
    }
  }
}