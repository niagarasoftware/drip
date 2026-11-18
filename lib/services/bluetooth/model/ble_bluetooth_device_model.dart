import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../utils/enums.dart';

class BleBluetoothDeviceModel {
  final BluetoothDevice device;
  BlueConnectionState connectionState;
  int? rssi;
  String? name;
  Map<String, dynamic>? deviceData;

  BleBluetoothDeviceModel({
    required this.device,
    required this.connectionState,
    this.rssi,
    this.name,
    this.deviceData,
  });

  // Getters for device information
  String get deviceId => device.remoteId.str;
  String get deviceName => name ?? (device.name.isNotEmpty ? device.name : device.platformName);

  // Connection state getters
  bool get isConnected => connectionState == BlueConnectionState.connected;
  bool get isConnecting => connectionState == BlueConnectionState.connecting;
  bool get isDisconnecting => connectionState == BlueConnectionState.disconnecting;
  bool get isDisconnected => connectionState == BlueConnectionState.disconnected;

  // Helper methods
  bool get isAvailable => !isConnected && !isConnecting && !isDisconnecting;


  @override
  String toString() {
    return 'BleBluetoothDeviceModel{name: $deviceName, id: $deviceId, state: $connectionState, rssi: $rssi}';
  }

  // Copy with method for updating state
  BleBluetoothDeviceModel copyWith({
    BluetoothDevice? device,
    BlueConnectionState? connectionState,
    int? rssi,
    String? name,
    Map<String, dynamic>? deviceData,
  }) {
    return BleBluetoothDeviceModel(
      device: device ?? this.device,
      connectionState: connectionState ?? this.connectionState,
      rssi: rssi ?? this.rssi,
      name: name ?? this.name,
      deviceData: deviceData ?? this.deviceData,
    );
  }
}