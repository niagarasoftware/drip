import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class BluetoothHelper {
  static const MethodChannel _channel = MethodChannel('com.niagaraautomations.oroDripirrigation/bluetooth');

  static Future<bool> removeBond(String macAddress) async {
    try {
      final bool result = await _channel.invokeMethod('removeBond', {'address': macAddress});
      return result;
    } catch (e) {
      debugPrint('Error removing bond: $e');
      return false;
    }
  }

  static Future<int> getBondState(String macAddress) async {
    try {
      final int bondState = await _channel.invokeMethod('getBondState', {'address': macAddress});
      return bondState;
    } catch (e) {
      debugPrint('Error getting bond state: $e');
      return 0; // BOND_NONE
    }
  }

  static Future<bool> clearGattCache(String macAddress) async {
    try {
      final bool result = await _channel.invokeMethod('clearGattCache', {'address': macAddress});
      return result;
    } catch (e) {
      debugPrint('Error clearing GATT cache: $e');
      return false;
    }
  }

  static Future<bool> refreshDeviceCache(String macAddress) async {
    try {
      final bool result = await _channel.invokeMethod('refreshDeviceCache', {'address': macAddress});
      return result;
    } catch (e) {
      debugPrint('Error refreshing device cache: $e');
      return false;
    }
  }

  static Future<bool> isBluetoothEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isBluetoothEnabled');
      return result;
    } catch (e) {
      debugPrint('Error checking Bluetooth state: $e');
      return false;
    }
  }

  static Future<void> enableBluetooth() async {
    try {
      await _channel.invokeMethod('enableBluetooth');
    } catch (e) {
      debugPrint('Error enabling Bluetooth: $e');
    }
  }

  static Future<void> disableBluetooth() async {
    try {
      await _channel.invokeMethod('disableBluetooth');
    } catch (e) {
      debugPrint('Error disabling Bluetooth: $e');
    }
  }

  static Future<List<String>> getConnectedDevices() async {
    try {
      final List<String> devices = await _channel.invokeMethod('getConnectedDevices');
      return devices;
    } catch (e) {
      debugPrint('Error getting connected devices: $e');
      return [];
    }
  }
}