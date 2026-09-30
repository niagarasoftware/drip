import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart' as classic;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../StateManagement/mqtt_payload_provider.dart';
import '../../utils/enums.dart';
import 'helper/bluetooth_activity_coordinator.dart';
import 'model/classic_bluetooth_device_model.dart';

class BluetoothClassicService {
  static BluetoothClassicService? _instance;
  BluetoothClassicService._internal();
  VoidCallback? onDeviceFound;

  Function()? onNoDeviceFound;
  Function(String message)? onConnectionError;
  Function(String message)? onBluetoothDisabled; // NEW: mirrors BLE service

  factory BluetoothClassicService() {
    _instance ??= BluetoothClassicService._internal();
    return _instance!;
  }

  final classic.FlutterBluetoothSerial _bluetooth = classic.FlutterBluetoothSerial.instance;
  final List<classic.BluetoothDevice> _devices = [];
  classic.BluetoothConnection? _connection;
  String? _connectedAddress;
  classic.BluetoothDevice? _connectedDeviceRef; // NEW: kept explicitly, no unsafe firstWhere
  MqttPayloadProvider? providerState;
  String _buffer = '';
  List<String> traceLog = [];
  bool isLogging = false;
  String traceChunk = '';

  bool _isScanning = false; // NEW: prevent overlapping discovery calls
  bool _isConnecting = false; // NEW: prevent overlapping connect attempts
  bool _manualDisconnect = false; // NEW
  int _reconnectAttempts = 0; // NEW
  static const int maxReconnectAttempts = 3;
  Timer? _reconnectTimer;
  StreamSubscription? _adapterStateSubscription; // NEW

  static const Duration connectTimeout = Duration(seconds: 15); // NEW
  static const Duration scanSafetyTimeout = Duration(seconds: 16); // NEW, fallback only

  bool get isConnected => _connection != null && _connection!.isConnected;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  StreamSubscription<classic.BluetoothDiscoveryResult>? _scanSubscription;

  Future<void> initializeClassicService({MqttPayloadProvider? state}) async {
    providerState = state;

    // NEW: let the coordinator fully stop us (not just pause scanning) if
    // the other stack needs the radio — a leftover live connection is
    // exactly what caused the bond churn seen in the logs.
    BluetoothActivityCoordinator.instance.onPauseClassic = () {
      hardStop();
    };

    // NEW: watch adapter state so the UI can react if Bluetooth is turned off mid-use,
    // the same way BluetoothBleService does.
    try {
      _adapterStateSubscription = _bluetooth.onStateChanged().listen((state) {
        debugPrint("🔵 Classic Bluetooth State: $state");
        if (state == classic.BluetoothState.STATE_OFF) {
          if (_connection != null) {
            _resetConnection();
            providerState?.updateClassicConnectedDeviceStatus(null);
          }
          onBluetoothDisabled?.call("Bluetooth was turned off. Please turn it back on to continue.");
        }
      });
    } catch (e) {
      debugPrint("⚠️ Could not listen to classic adapter state: $e");
    }
  }

  Future<void> initPermissions() async {
    try {
      final isEnabled = await _bluetooth.isEnabled;
      if (!(isEnabled ?? false)) {
        await _bluetooth.requestEnable();
      }
    } catch (e) {
      debugPrint('Error enabling Bluetooth: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        final List<Permission> permissions = [
          if (sdkInt >= 31) ...[
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
          ] else ...[
            Permission.bluetooth,
          ],
          Permission.locationWhenInUse,
        ];

        final statuses = await permissions.request();
        if (statuses.values.any((status) => status.isDenied || status.isPermanentlyDenied)) {
          debugPrint('Permissions not granted');
          return false;
        }
      } catch (e) {
        debugPrint("⚠️ Error requesting classic BT permissions: $e");
        return false;
      }
    }
    return true;
  }

  int getTraceLogSize() {
    int totalBytes = 0;
    for (final str in traceLog) {
      totalBytes += utf8.encode(str).length;
    }
    return totalBytes;
  }

  Future<void> checkLocationServices() async {
    try {
      bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        debugPrint("Location services are OFF. Prompting user...");
        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      debugPrint("⚠️ Error checking location services: $e");
    }
  }

  int getCurrentChunkSize() {
    return utf8.encode(traceChunk).length;
  }

  /// Scans for classic Bluetooth devices matching [deviceId].
  /// Fixed to: avoid overlapping scans, avoid duplicate permission/location
  /// calls, and wait for the discovery stream to actually finish instead of
  /// a fixed 10s guess (which was cutting discovery short inconsistently).
  Future<void> scanDevices(String deviceId) async {
    if (_isScanning) {
      debugPrint("⚠️ Classic scan already in progress");
      return;
    }

    // NEW: make sure BLE isn't mid-scan/connect on the same radio.
    await BluetoothActivityCoordinator.instance.claim(BluetoothStack.classic);

    try {
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        onConnectionError?.call("Bluetooth permissions are required to scan for devices.");
        return;
      }

      await checkLocationServices();

      _devices.clear();
      try {
        providerState?.updateClassicPairedDevices([]);
      } catch (e) {
        debugPrint("⚠️ Error clearing classic provider devices: $e");
      }

      // Make sure nothing stale is running before we start.
      await classic.FlutterBluetoothSerial.instance.cancelDiscovery();

      _isScanning = true;
      final completer = Completer<void>();

      _scanSubscription = classic.FlutterBluetoothSerial.instance.startDiscovery().listen(
            (result) {
          final device = result.device;

          if ((device.name?.contains(deviceId) ?? false)) {
            final exists = _devices.any((d) => d.address == device.address);
            if (!exists) {
              _devices.add(device);

              final existing = providerState?.pairedDevicesClassic.firstWhere(
                    (e) => e.device.address == device.address,
                orElse: () => ClassicBluetoothDeviceModel(device: device),
              );

              final updatedDevice = ClassicBluetoothDeviceModel(
                device: device,
                connectionState: existing?.connectionState ?? BlueConnectionState.disconnected,
              );

              final updatedList = [
                ...(providerState?.pairedDevicesClassic
                    .where((d) => d.device.address != device.address)
                    .toList() ??
                    <ClassicBluetoothDeviceModel>[]),
                updatedDevice,
              ];

              providerState?.updateClassicPairedDevices(updatedList);
            }
            onDeviceFound?.call();
          }
        },
        onError: (e) {
          debugPrint("❌ Classic discovery stream error: $e");
          onConnectionError?.call("Bluetooth scan failed: $e");
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          // NEW: this fires when Android's native discovery actually finishes
          // (~12s typically) instead of us guessing a fixed delay.
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      // Safety net only — if onDone never fires for some reason, don't hang forever.
      await completer.future.timeout(
        scanSafetyTimeout,
        onTimeout: () => debugPrint("⏱️ Classic scan safety timeout hit"),
      );

      await _scanSubscription?.cancel();
      _scanSubscription = null;
      await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
      _isScanning = false;

      if (_devices.isEmpty) {
        debugPrint("⚠️ Classic scan finished — no matching devices found");
        onNoDeviceFound?.call();
      }
    } catch (e) {
      debugPrint("❌ Error during classic scan: $e");
      _isScanning = false;
      onConnectionError?.call("Bluetooth scan failed: $e");
    } finally {
      BluetoothActivityCoordinator.instance.release(BluetoothStack.classic);
    }
  }

  /// Connects to a classic device.
  /// Fixed to: time out instead of hanging forever, check/request OS-level
  /// bonding first (classic SPP is far less reliable when unbonded), and
  /// avoid overlapping connect attempts.
  Future<void> connectToDevice(ClassicBluetoothDeviceModel device) async {
    if (_isConnecting) {
      debugPrint("⚠️ Classic connection already in progress");
      return;
    }

    // NEW: if we're already connected to this exact device, don't tear the
    // connection down and reopen it — just confirm state to the UI and
    // return. This is what was causing an unnecessary disconnect/reconnect
    // every time the user came back to this screen (e.g. after switching
    // BLE<->WiFi mode) even though the socket was still perfectly alive.
    if (isConnected && _connectedAddress == device.device.address) {
      debugPrint("✅ Classic already connected to ${device.device.address} — skipping reconnect");
      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.connected.index);
      providerState?.updateClassicConnectedDeviceStatus(device);
      return;
    }

    _isConnecting = true;
    _manualDisconnect = false;

    // NEW: make sure BLE isn't mid-scan/connect on the same radio.
    await BluetoothActivityCoordinator.instance.claim(BluetoothStack.classic);

    try {
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        onConnectionError?.call("Bluetooth permissions are required to connect.");
        _isConnecting = false;
        return;
      }

      await initPermissions();
      await checkLocationServices();

      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.connecting.index);

      // NEW: only close the existing connection if it's to a *different*
      // device. (isConnected && same address was already handled above.)
      if (isConnected) {
        debugPrint("🔌 Switching devices — closing existing classic connection first");
        await disconnect();
      }

      // NEW: ensure the device is bonded at the OS level before opening an
      // SPP socket. Unbonded classic connections are the single biggest
      // cause of "works sometimes" behavior on Android.
      try {
        final bondState = await _bluetooth.getBondStateForAddress(device.device.address);
        if (bondState != classic.BluetoothBondState.bonded) {
          debugPrint("🔗 Device not bonded, requesting bonding first...");
          final bonded = await _bluetooth.bondDeviceAtAddress(device.device.address);
          if (bonded != true) {
            debugPrint("⚠️ Bonding did not complete, attempting connection anyway");
          }
        }
      } catch (e) {
        // Some plugin versions/platforms may not support these calls — degrade gracefully.
        debugPrint("⚠️ Bond-state check not available/failed: $e");
      }

      _connectedAddress = device.device.address;
      _connectedDeviceRef = device.device;

      // NEW: make sure discovery is truly stopped and the radio has settled
      // before opening the RFCOMM socket. Connecting while discovery/SDP is
      // still winding down is the #1 cause of "read failed, socket might
      // closed or timeout" on the very first connect attempt.
      try {
        await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 600));

      final connection = await _connectWithSingleRetry(device.device.address);
      _connection = connection;
      _reconnectAttempts = 0;

      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.connected.index);
      providerState?.updateClassicConnectedDeviceStatus(device);

      connection.input?.listen((Uint8List data) {
        _buffer += utf8.decode(data);
        _parseBuffer();
      }).onDone(() {
        final wasConnected = _connection != null;
        _connection = null;
        providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.disconnected.index);
        providerState?.updateClassicConnectedDeviceStatus(null);

        if (wasConnected && !_manualDisconnect) {
          onConnectionError?.call("Device is disconnected");
          _attemptReconnect(device);
        }
      });

      _isConnecting = false;
    } on TimeoutException catch (e) {
      debugPrint("❌ Classic connection timed out: $e");
      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.disconnected.index);
      providerState?.updateClassicConnectedDeviceStatus(null);
      onConnectionError?.call("Connection timed out. Please make sure the device is powered on and nearby.");
      _isConnecting = false;
    } catch (e) {
      debugPrint("Connection failed: $e");
      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.disconnected.index);
      providerState?.updateClassicConnectedDeviceStatus(null);
      onConnectionError?.call(e.toString());
      _isConnecting = false;
    } finally {
      // Release the radio claim once the connect attempt is resolved (success
      // or failure) — we don't need to hold it for the lifetime of the connection.
      BluetoothActivityCoordinator.instance.release(BluetoothStack.classic);
    }
  }

  // NEW: the first classic connect() after a scan/pairing very commonly fails
  // with "read failed, socket might closed or timeout" simply because
  // Android's SDP cache for that device isn't warm yet. A single immediate
  // retry resolves this the large majority of the time, so we do it here
  // rather than surfacing a scary error to the user on attempt #1.
  Future<classic.BluetoothConnection> _connectWithSingleRetry(String address) async {
    try {
      return await classic.BluetoothConnection.toAddress(address).timeout(
        connectTimeout,
        onTimeout: () => throw TimeoutException("Connection timed out after ${connectTimeout.inSeconds}s"),
      );
    } catch (e) {
      final message = e.toString();
      final isKnownFirstAttemptFailure =
          message.contains('read failed') || message.contains('connect_error') || message.contains('socket might closed');
      if (!isKnownFirstAttemptFailure) rethrow;

      debugPrint("⚠️ Classic connect failed on first attempt (known SDP-cache issue), retrying once: $e");
      await Future.delayed(const Duration(milliseconds: 800));
      return await classic.BluetoothConnection.toAddress(address).timeout(
        connectTimeout,
        onTimeout: () => throw TimeoutException("Connection timed out after ${connectTimeout.inSeconds}s"),
      );
    }
  }

  // NEW: mirrors BLE service's reconnect behavior, capped at maxReconnectAttempts.
  void _attemptReconnect(ClassicBluetoothDeviceModel device) {
    if (_reconnectTimer != null || _manualDisconnect) return;
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint("❌ Classic: max reconnect attempts reached. Manual reconnect required.");
      _reconnectAttempts = 0;
      return;
    }
    _reconnectAttempts++;
    debugPrint("🔄 Classic auto-reconnect attempt $_reconnectAttempts/$maxReconnectAttempts in 5 seconds...");
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      _reconnectTimer = null;
      if (!isConnected && !_isConnecting && !_manualDisconnect) {
        await connectToDevice(device);
      }
    });
  }

  Future<void> stopDiscovery() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
  }

  /// NEW: fully tears this stack down — stops discovery, cancels the
  /// reconnect loop, and closes any live connection. Call this whenever the
  /// user switches to a different controller/master, and whenever the other
  /// Bluetooth stack (BLE) needs exclusive use of the radio. Unlike
  /// disconnect(), this is meant to be safe to call even when nothing is
  /// connected.
  Future<void> hardStop() async {
    debugPrint("🛑 Classic hardStop — releasing radio for other stack");
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    await stopDiscovery();
    if (_connection != null) {
      try {
        await _connection?.close();
      } catch (e) {
        debugPrint("⚠️ Error closing classic connection during hardStop: $e");
      }
    }
    _connection = null;
    _connectedAddress = null;
    _connectedDeviceRef = null;
    providerState?.updateClassicConnectedDeviceStatus(null);
    Future.delayed(const Duration(seconds: 1), () => _manualDisconnect = false);
  }

  Future<void> resetBluetoothState() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
    _devices.clear();
    providerState?.updateClassicPairedDevices([]);
  }

  void _parseBuffer() {
    debugPrint('_buffer----> $_buffer');

    if (_buffer.isEmpty) return;

    if (_buffer.contains('LogFileSentSuccess')) {
      isLogging = false;
      traceLog.add(traceChunk);
      providerState?.updateTraceLogs(traceLog);
      providerState?.setTraceLoading(false);

      int sizeInBytes = getTraceLogSize();
      debugPrint('TraceLog size in bytes: $sizeInBytes');
      providerState?.setTraceLoadingsize(sizeInBytes);

      traceChunk = '';
    }
    if (_buffer.contains('*StartLog')) {
      isLogging = true;
      traceChunk = '';

      final startIndex = _buffer.indexOf('*StartLog');
      traceChunk += _buffer.substring(startIndex);
      int sizeInBytes = getCurrentChunkSize();
      providerState?.setTraceLoadingsize(sizeInBytes);
    }

    if (isLogging && !_buffer.contains('*StartLog')) {
      traceChunk += _buffer;
      int sizeInBytes = getCurrentChunkSize();
      providerState?.setTraceLoadingsize(sizeInBytes);
    }

    final sizeMatch = RegExp(r'LogFileSize:(\d+)').firstMatch(_buffer);
    if (sizeMatch != null) {
      final sizeStr = sizeMatch.group(1);
      final totalSize = int.tryParse(sizeStr ?? '0') ?? 0;
      providerState?.setTotalTraceSize(totalSize);
    }

    if (isLogging) {
      providerState?.setTraceLoading(true);
    }

    while (_buffer.contains('*Start') && _buffer.contains('#End')) {
      final start = _buffer.indexOf('*Start');
      final end = _buffer.indexOf('#End', start);

      if (start != -1 && end != -1 && end > start) {
        final jsonString = _buffer.substring(start + 6, end).trim();
        _processData(jsonString);
        _buffer = _buffer.substring(end + 4);
      } else {
        break;
      }
    }
  }

  void _processData(String jsonString) {
    debugPrint("_processData call $jsonString");
    try {
      final data = json.decode(jsonString);
      final jsonStr = json.encode(data);

      providerState?.updateReceivedPayload(jsonStr, false);

      switch (data['mC'].toString()) {
        case '7300':
          final rawList = data["cM"]?["7301"]?["ListOfWifi"];
          final wifiStatus = data["cM"]?["7301"]?["Status"];
          final interfaceType = data["cM"]?["7301"]?["InterfaceType"];
          final ipAddress = data["cM"]?["7301"]?["IpAddress"];

          providerState?.updateWifiStatus(wifiStatus, false);
          providerState?.updateInterfaceType(interfaceType);
          providerState?.updateIpAddress(ipAddress);

          if (rawList is List) {
            final wifiList = rawList.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
            providerState?.updateWifiList(wifiList);
          }
          break;
        case '4200':
          final message = data['cM']?.entries.first.value['Message']?.trim();
          if (message != null) {
            providerState?.updateWifiMessage(message);
          }
          break;
        case '6600':
          providerState?.updateReceivedPayload(jsonStr, false);
          break;
        default:
          providerState?.updateReceivedPayload(jsonStr, true);
          break;
      }
    } catch (e) {
      debugPrint("Error parsing: $e");
    }
  }

  Future<void> write(String payload) async {
    if (_connection != null && _connection!.isConnected) {
      final finalPayload = '*$payload#';
      debugPrint("Sending: $finalPayload");
      _connection!.output.add(Uint8List.fromList(utf8.encode("$finalPayload\r\n")));
    }
  }

  Future<void> writeFW(List<int> data) async {
    if (_connection != null && _connection!.isConnected) {
      debugPrint("Sending ${data.length} bytes over Bluetooth...");
      _connection!.output.add(Uint8List.fromList(data));
      await _connection!.output.allSent;
    } else {
      debugPrint("Not connected");
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    try {
      await _connection?.close();
    } catch (e) {
      debugPrint("Disconnect failed: $e");
    } finally {
      _connection = null;
      _connectedAddress = null;
      _connectedDeviceRef = null;
      providerState?.updateClassicConnectedDeviceStatus(null);
    }
    Future.delayed(const Duration(seconds: 2), () {
      _manualDisconnect = false;
    });
  }

  void _resetConnection() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      _connection?.close();
    } catch (_) {}
    _connection = null;
    _connectedAddress = null;
    _connectedDeviceRef = null;
    _buffer = '';
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await stopDiscovery();
    await _adapterStateSubscription?.cancel();
    _resetConnection();
    onDeviceFound = null;
    onNoDeviceFound = null;
    onConnectionError = null;
    onBluetoothDisabled = null;
  }

  // FIXED: was `_devices.firstWhere(...)` with no orElse — threw StateError
  // whenever the address wasn't in _devices (e.g. after a failed connect).
  // Now backed by the reference captured at connect time.
  classic.BluetoothDevice? get connectedDevice => _connectedDeviceRef;
}

/*
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart' as classic;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../StateManagement/mqtt_payload_provider.dart';
import '../../utils/enums.dart';
import 'model/classic_bluetooth_device_model.dart';


class BluetoothClassicService {
  static BluetoothClassicService? _instance;
  BluetoothClassicService._internal();
  VoidCallback? onDeviceFound;

  // 👇 new callbacks
  Function()? onNoDeviceFound;
  Function(String message)? onConnectionError;

  factory BluetoothClassicService() {
    _instance ??= BluetoothClassicService._internal();
    return _instance!;
  }

  final classic.FlutterBluetoothSerial _bluetooth = classic.FlutterBluetoothSerial.instance;
  final List<classic.BluetoothDevice> _devices = [];
  classic.BluetoothConnection? _connection;
  String? _connectedAddress;
  MqttPayloadProvider? providerState;
  String _buffer = '';
  List<String> traceLog = [];
  bool isLogging = false;
  String traceChunk = '';

  bool get isConnected => _connection != null && _connection!.isConnected;
  StreamSubscription<classic.BluetoothDiscoveryResult>? _scanSubscription;

  Future<void> initializeClassicService({MqttPayloadProvider? state}) async {
    providerState = state;
  }

  Future<void> initPermissions() async {
    try {
      final isEnabled = await _bluetooth.isEnabled;
      if (!(isEnabled ?? false)) {
        await _bluetooth.requestEnable();
      }
    } catch (e) {
      debugPrint('Error enabling Bluetooth: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      final List<Permission> permissions = [
        if (sdkInt >= 31) ...[
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ] else ...[
          Permission.bluetooth,
        ],
        Permission.locationWhenInUse,
      ];

      final statuses = await permissions.request();
      if (statuses.values.any((status) => status.isDenied || status.isPermanentlyDenied)) {
        debugPrint('Permissions not granted');
        return false;
      }
    }
    return true;
  }


  int getTraceLogSize() {
    int totalBytes = 0;
    for (final str in traceLog) {
      totalBytes += utf8.encode(str).length;
    }
    return totalBytes;
  }

  Future<void> checkLocationServices() async {
    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      debugPrint("Location services are OFF. Prompting user...");
      await Geolocator.openLocationSettings();
    }
  }

  int getCurrentChunkSize() {
    return utf8.encode(traceChunk).length;
  }

  Future<void> scanDevices(String deviceId) async {
    try {
      // Permission check up front — fail loudly if denied
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        onConnectionError?.call("Bluetooth permissions are required to scan for devices.");
        return;
      }

      await checkLocationServices();

      _devices.clear();
      await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
      await requestPermissions();
      await checkLocationServices();

      _scanSubscription = classic.FlutterBluetoothSerial.instance.startDiscovery().listen(
            (result) {
          final device = result.device;

          if ((device.name?.contains(deviceId) ?? false)) {
            final exists = _devices.any((d) => d.address == device.address);
            if (!exists) {
              _devices.add(device);

              final existing = providerState?.pairedDevicesClassic.firstWhere(
                    (e) => e.device.address == device.address,
                orElse: () => ClassicBluetoothDeviceModel(device: device),
              );

              final updatedDevice = ClassicBluetoothDeviceModel(
                device: device,
                connectionState: existing?.connectionState ?? BlueConnectionState.disconnected,
              );

              final updatedList = [
                ...(providerState?.pairedDevicesClassic
                    .where((d) => d.device.address != device.address)
                    .toList() ??
                    <ClassicBluetoothDeviceModel>[]),
                updatedDevice,
              ];

              providerState?.updateClassicPairedDevices(updatedList);
            }
            onDeviceFound?.call();
          }
        },
        onError: (e) {
          debugPrint("❌ Classic discovery stream error: $e");
          onConnectionError?.call("Bluetooth scan failed: $e");
        },
      );

      await Future.delayed(const Duration(seconds: 10));
      await _scanSubscription?.cancel();
      await classic.FlutterBluetoothSerial.instance.cancelDiscovery();

      // 👇 tell the UI if nothing was found
      if (_devices.isEmpty) {
        debugPrint("⚠️ Classic scan finished — no matching devices found");
        onNoDeviceFound?.call();
      }
    } catch (e) {
      debugPrint("❌ Error during classic scan: $e");
      onConnectionError?.call("Bluetooth scan failed: $e");
    }
  }

  Future<void> connectToDevice(ClassicBluetoothDeviceModel device) async {
    try {
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        onConnectionError?.call("Bluetooth permissions are required to connect.");
        return;
      }

      await initPermissions();
      await checkLocationServices();

      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.connecting.index);

      if (isConnected) {
        await disconnect();
      }

      _connectedAddress = device.device.address;
      final connection = await classic.BluetoothConnection.toAddress(device.device.address);
      _connection = connection;

      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.connected.index);
      providerState?.updateClassicConnectedDeviceStatus(device);

      connection.input.listen((Uint8List data) {
        _buffer += utf8.decode(data);
        _parseBuffer();
      }).onDone(() {
        final wasConnected = _connection != null;
        _connectedAddress = null;
        _connection = null;
        providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.disconnected.index);
        providerState?.updateClassicConnectedDeviceStatus(null);

        // 👇 if it dropped unexpectedly (not via manual disconnect()), surface it
        if (wasConnected) {
          onConnectionError?.call("Device is disconnected");
        }
      });
    } catch (e) {
      debugPrint("Connection failed: $e");
      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.disconnected.index);
      providerState?.updateClassicConnectedDeviceStatus(null);
      onConnectionError?.call(e.toString()); // 👈 surface the failure reason
    }
  }

  Future<void> stopDiscovery() async {
    await _scanSubscription?.cancel();
    await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
  }

  Future<void> resetBluetoothState() async {
    await _scanSubscription?.cancel();
    await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
    _devices.clear();
    providerState?.updateClassicPairedDevices([]);
  }

  void _parseBuffer() {
    debugPrint('_buffer----> $_buffer');

    if (_buffer.isEmpty) return;

    if (_buffer.contains('LogFileSentSuccess')) {
      isLogging = false;
      traceLog.add(traceChunk);
      providerState?.updateTraceLogs(traceLog);
      providerState?.setTraceLoading(false);

      int sizeInBytes = getTraceLogSize();
      debugPrint('TraceLog size in bytes: $sizeInBytes');
      providerState?.setTraceLoadingsize(sizeInBytes);

      traceChunk = '';
    }
    if (_buffer.contains('*StartLog')) {
      isLogging = true;
      traceChunk = '';

      final startIndex = _buffer.indexOf('*StartLog');
      traceChunk += _buffer.substring(startIndex);
      int sizeInBytes = getCurrentChunkSize();
      providerState?.setTraceLoadingsize(sizeInBytes);
    }

    if (isLogging && !_buffer.contains('*StartLog')) {
      traceChunk += _buffer;
      int sizeInBytes = getCurrentChunkSize();
      providerState?.setTraceLoadingsize(sizeInBytes);
    }

    final sizeMatch = RegExp(r'LogFileSize:(\d+)').firstMatch(_buffer);
    if (sizeMatch != null) {
      final sizeStr = sizeMatch.group(1);
      final totalSize = int.tryParse(sizeStr ?? '0') ?? 0;
      providerState?.setTotalTraceSize(totalSize);
    }

    if (isLogging) {
      providerState?.setTraceLoading(true);
    }

    while (_buffer.contains('*Start') && _buffer.contains('#End')) {
      final start = _buffer.indexOf('*Start');
      final end = _buffer.indexOf('#End', start);

      if (start != -1 && end != -1 && end > start) {
        final jsonString = _buffer.substring(start + 6, end).trim();
        _processData(jsonString);
        _buffer = _buffer.substring(end + 4);
      } else {
        break;
      }
    }
  }

  void _processData(String jsonString) {
    debugPrint("_processData call $jsonString");
    try {
      final data = json.decode(jsonString);
      final jsonStr = json.encode(data);

      providerState?.updateReceivedPayload(jsonStr, false);

      switch (data['mC'].toString()) {
        case '7300':
          final rawList = data["cM"]?["7301"]?["ListOfWifi"];
          final wifiStatus = data["cM"]?["7301"]?["Status"];
          final interfaceType = data["cM"]?["7301"]?["InterfaceType"];
          final ipAddress = data["cM"]?["7301"]?["IpAddress"];

          providerState?.updateWifiStatus(wifiStatus, false);
          providerState?.updateInterfaceType(interfaceType);
          providerState?.updateIpAddress(ipAddress);

          if (rawList is List) {
            final wifiList = rawList.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
            providerState?.updateWifiList(wifiList);
          }
          break;
        case '4200':
          final message = data['cM']?.entries.first.value['Message']?.trim();
          if (message != null) {
            providerState?.updateWifiMessage(message);
          }
          break;
        case '6600':
          providerState?.updateReceivedPayload(jsonStr, false);
          break;
        default:
          providerState?.updateReceivedPayload(jsonStr, true);
          break;
      }
    } catch (e) {
      debugPrint("Error parsing: $e");
    }
  }

  Future<void> write(String payload) async {
    if (_connection != null && _connection!.isConnected) {
      final finalPayload = '*$payload#';
      debugPrint("Sending: $finalPayload");
      _connection!.output.add(Uint8List.fromList(utf8.encode("$finalPayload\r\n")));
    }
  }

  Future<void> writeFW(List<int> data) async {
    if (_connection != null && _connection!.isConnected) {
      debugPrint("Sending ${data.length} bytes over Bluetooth...");
      _connection!.output.add(Uint8List.fromList(data));
      await _connection!.output.allSent;
    } else {
      debugPrint("Not connected");
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (e) {
      debugPrint("Disconnect failed: $e");
    } finally {
      _connection = null;
      _connectedAddress = null;
      providerState?.updateClassicConnectedDeviceStatus(null);
    }
  }

  classic.BluetoothDevice? get connectedDevice {
    return _devices.firstWhere((d) => d.address == _connectedAddress);
  }
}
*/


/*
class BluetoothClassicService {
  static BluetoothClassicService? _instance;
  BluetoothClassicService._internal();
  VoidCallback? onDeviceFound;

  factory BluetoothClassicService() {
    _instance ??= BluetoothClassicService._internal();
    return _instance!;
  }

  final classic.FlutterBluetoothSerial _bluetooth = classic.FlutterBluetoothSerial.instance;
  final List<classic.BluetoothDevice> _devices = [];
  classic.BluetoothConnection? _connection;
  String? _connectedAddress;
  MqttPayloadProvider? providerState;
  String _buffer = '';
  List<String> traceLog = [];
  bool isLogging = false;
  String traceChunk = '';

  bool get isConnected => _connection != null && _connection!.isConnected;
  StreamSubscription<classic.BluetoothDiscoveryResult>? _scanSubscription;

  Future<void> initializeClassicService({MqttPayloadProvider? state}) async {
    providerState = state;
  }

  Future<void> initPermissions() async {
    try {
      final isEnabled = await _bluetooth.isEnabled;
      if (!(isEnabled ?? false)) {
        await _bluetooth.requestEnable();
      }
    } catch (e) {
      debugPrint('Error enabling Bluetooth: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      final List<Permission> permissions = [
        if (sdkInt >= 31) ...[
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ] else ...[
          Permission.bluetooth,
        ],
        Permission.locationWhenInUse,
      ];

      final statuses = await permissions.request();
      if (statuses.values.any((status) => status.isDenied || status.isPermanentlyDenied)) {
        debugPrint('Permissions not granted');
        return false;
      }
    }
    return true;
  }


  int getTraceLogSize() {
    int totalBytes = 0;
    for (final str in traceLog) {
      totalBytes += utf8.encode(str).length;
    }
    return totalBytes;
  }

  Future<void> checkLocationServices() async {
    bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      debugPrint("Location services are OFF. Prompting user...");
      await Geolocator.openLocationSettings();
    }
  }

  int getCurrentChunkSize() {
    return utf8.encode(traceChunk).length;
  }

  Future<void> scanDevices(String deviceId) async {

    await requestPermissions();
    await checkLocationServices();

    _devices.clear();
    await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
    await requestPermissions();
    await checkLocationServices();

    _scanSubscription = classic.FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
      final device = result.device;

      if ((device.name?.contains(deviceId) ?? false)) {
        final exists = _devices.any((d) => d.address == device.address);
        if (!exists) {
          _devices.add(device);

          final existing = providerState?.pairedDevicesClassic.firstWhere(
                (e) => e.device.address == device.address,
            orElse: () => ClassicBluetoothDeviceModel(device: device),
          );

          final updatedDevice = ClassicBluetoothDeviceModel(
            device: device,
            connectionState: existing?.connectionState ?? BlueConnectionState.disconnected,
          );

          final updatedList = [
            ...(providerState?.pairedDevicesClassic
                .where((d) => d.device.address != device.address)
                .toList() ??
                <ClassicBluetoothDeviceModel>[]),
            updatedDevice,
          ];

          providerState?.updateClassicPairedDevices(updatedList);
        }
        onDeviceFound?.call();
      }
    });

    await Future.delayed(const Duration(seconds: 10));
    await _scanSubscription?.cancel();
    await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
  }

  Future<void> connectToDevice(ClassicBluetoothDeviceModel device) async {
    try {
      await requestPermissions();
      await initPermissions();
      await checkLocationServices();

      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.connecting.index);

      if (isConnected) {
        await disconnect();
      }

      _connectedAddress = device.device.address;
      final connection = await classic.BluetoothConnection.toAddress(device.device.address);
      _connection = connection;

      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.connected.index);
      providerState?.updateClassicConnectedDeviceStatus(device);

      connection.input?.listen((Uint8List data) {
        _buffer += utf8.decode(data);
        _parseBuffer();
      }).onDone(() {
        _connectedAddress = null;
        _connection = null;
        providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.disconnected.index);
        providerState?.updateClassicConnectedDeviceStatus(null);
      });
    } catch (e) {
      debugPrint("Connection failed: $e");
      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.disconnected.index);
      providerState?.updateClassicConnectedDeviceStatus(null);
    }
  }

  Future<void> stopDiscovery() async {
    await _scanSubscription?.cancel();
    await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
  }

  Future<void> resetBluetoothState() async {
    // stop scan
    await _scanSubscription?.cancel();
    await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
    _devices.clear();
    providerState?.updateClassicPairedDevices([]);
  }

  void _parseBuffer() {
    debugPrint('_buffer----> $_buffer');

    if (_buffer.isEmpty) return;

    // Start logging when *StartLog appears
    if (_buffer.contains('LogFileSentSuccess')) {
      isLogging = false;

      traceLog.add(traceChunk); // Add collected chunk to log
      providerState?.updateTraceLogs(traceLog);

      providerState?.setTraceLoading(false);

      int sizeInBytes = getTraceLogSize();
      debugPrint('TraceLog size in bytes: $sizeInBytes');
      providerState?.setTraceLoadingsize(sizeInBytes);

      traceChunk = ''; // Clear buffer for next round
    }
    if (_buffer.contains('*StartLog')) {
      isLogging = true;
      traceChunk = ''; // Reset previous chunk

      final startIndex = _buffer.indexOf('*StartLog');
      traceChunk += _buffer.substring(startIndex);
      int sizeInBytes = getCurrentChunkSize();
      providerState?.setTraceLoadingsize(sizeInBytes);
    }

    // Continue logging: append new data to traceChunk
    if (isLogging && !_buffer.contains('*StartLog')) {
      traceChunk += _buffer;
      int sizeInBytes = getCurrentChunkSize();
      providerState?.setTraceLoadingsize(sizeInBytes);
    }

    // Extract and set LogFileSize if available
    final sizeMatch = RegExp(r'LogFileSize:(\d+)').firstMatch(_buffer);
    if (sizeMatch != null) {
      final sizeStr = sizeMatch.group(1);
      final totalSize = int.tryParse(sizeStr ?? '0') ?? 0;
      providerState?.setTotalTraceSize(totalSize);
    }

    // While logging, show loading
    if (isLogging) {
      providerState?.setTraceLoading(true);
    }

    // Handle JSON packets between *Start and #End
    while (_buffer.contains('*Start') && _buffer.contains('#End')) {
      final start = _buffer.indexOf('*Start');
      final end = _buffer.indexOf('#End', start);

      if (start != -1 && end != -1 && end > start) {
        final jsonString = _buffer.substring(start + 6, end).trim();
        _processData(jsonString);
        _buffer = _buffer.substring(end + 4); // skip past '#End'
      } else {
        break;
      }
    }

    // Do NOT clear _buffer fully—let it continue accumulating partial data
  }


  void _processData(String jsonString) {
    debugPrint("_processData call $jsonString");
    try {
      final data = json.decode(jsonString);
      final jsonStr = json.encode(data);

      providerState?.updateReceivedPayload(jsonStr, false);

      switch (data['mC'].toString()) {
        case '7300':
          final rawList = data["cM"]?["7301"]?["ListOfWifi"];
          final wifiStatus = data["cM"]?["7301"]?["Status"];
          final interfaceType = data["cM"]?["7301"]?["InterfaceType"];
          final ipAddress = data["cM"]?["7301"]?["IpAddress"];

          providerState?.updateWifiStatus(wifiStatus, false);
          providerState?.updateInterfaceType(interfaceType);
          providerState?.updateIpAddress(ipAddress);

          if (rawList is List) {
            final wifiList = rawList.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
            providerState?.updateWifiList(wifiList);
          }
          break;
        case '4200':
          final message = data['cM']?.entries.first.value['Message']?.trim();
          if (message != null) {
            providerState?.updateWifiMessage(message);
          }
          break;
        case '6600':
          providerState?.updateReceivedPayload(jsonStr, false);
          break;
        default:
          providerState?.updateReceivedPayload(jsonStr, true);
          break;
      }
    } catch (e) {
      debugPrint("Error parsing: $e");
    }
  }

  Future<void> write(String payload) async {
    if (_connection != null && _connection!.isConnected) {
      final finalPayload = '*$payload#';
      debugPrint("Sending: $finalPayload");
      _connection!.output.add(Uint8List.fromList(utf8.encode("$finalPayload\r\n")));
    }
  }

  Future<void> writeFW(List<int> data) async {
    if (_connection != null && _connection!.isConnected) {
      debugPrint("Sending ${data.length} bytes over Bluetooth...");
      _connection!.output.add(Uint8List.fromList(data)); // send raw bytes
      await _connection!.output.allSent; // ensure it's flushed
    } else {
      debugPrint("Not connected");
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (e) {
      debugPrint("Disconnect failed: $e");
    } finally {
      _connection = null;
      _connectedAddress = null;
      providerState?.updateClassicConnectedDeviceStatus(null);
    }
  }

  classic.BluetoothDevice? get connectedDevice {
    return _devices.firstWhere((d) => d.address == _connectedAddress);
  }
}*/
