import 'package:flutter/foundation.dart';

/// Both BluetoothBleService and BluetoothClassicService are app-lifetime
/// singletons. If a BLE scan/connect and a Classic scan/connect happen at
/// the same moment, Android's Bluetooth stack frequently fails the Classic
/// RFCOMM connect with "read failed, socket might closed or timeout" —
/// this is exactly what showed up in the logs (FlutterBluePluginPlus
/// connecting at the same instant the classic connect() was in flight).
///
/// This coordinator gives each service a way to say "I need the radio" and
/// "I'm done with the radio" so the other one can back off first.
///
/// Usage:
///   await BluetoothActivityCoordinator.instance.claim(BluetoothStack.classic);
///   try { ... do the scan/connect ... }
///   finally { BluetoothActivityCoordinator.instance.release(BluetoothStack.classic); }
enum BluetoothStack { ble, classic }

class BluetoothActivityCoordinator {
  BluetoothActivityCoordinator._internal();
  static final BluetoothActivityCoordinator instance = BluetoothActivityCoordinator._internal();

  BluetoothStack? _activeStack;

  /// Called by BluetoothBleService when it starts a scan or connect.
  /// Register this from BluetoothBleService, e.g.:
  ///   Function()? onPauseRequested; // set by coordinator
  Function()? onPauseBle;

  /// Called by BluetoothClassicService when it starts a scan or connect.
  Function()? onPauseClassic;

  /// Call before starting any radio-heavy operation (scan, connect).
  /// If the other stack is active, asks it to stand down first and waits
  /// briefly for the radio to settle.
  Future<void> claim(BluetoothStack stack) async {
    if (_activeStack != null && _activeStack != stack) {
      debugPrint("📡 $stack requesting radio, pausing $_activeStack first");
      if (_activeStack == BluetoothStack.ble) {
        onPauseBle?.call();
      } else {
        onPauseClassic?.call();
      }
      // Give the other stack's stopScan()/cancelDiscovery() time to land.
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _activeStack = stack;
  }

  void release(BluetoothStack stack) {
    if (_activeStack == stack) {
      _activeStack = null;
    }
  }
}