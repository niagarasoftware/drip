import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart' as classic;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';

import '../../Constants/constants.dart';
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
  Function(String message)? onBluetoothDisabled;
  Function(String message, bool success)? onWifiUpdateResult; // NEW: mirrors BLE service

  factory BluetoothClassicService() {
    _instance ??= BluetoothClassicService._internal();
    return _instance!;
  }

  final classic.FlutterBluetoothSerial _bluetooth = classic.FlutterBluetoothSerial.instance;
  final List<classic.BluetoothDevice> _devices = [];
  classic.BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSubscription; // NEW
  String? _connectedAddress;
  classic.BluetoothDevice? _connectedDeviceRef;
  MqttPayloadProvider? providerState;
  List<String> traceLog = [];
  bool isLogging = false;
  String traceChunk = '';

  // ---------------- response buffer (same idea as BLE service) ----------------
  String _buffer = '';
  Timer? _bufferStaleTimer; // NEW
  static const int bufferStaleTimeoutMS = 5000; // NEW
  bool _isReceivingMessage = false; // NEW
  DateTime? _lastActivity; // NEW

  // ---------------- write settings ----------------
  /// Payload is sent in small pieces, step by step, until the full payload
  /// has been written. Tune these two values if the device needs it slower/faster.
  static const int writeChunkSize = 20; // bytes per piece
  static const int writeChunkDelayMs = 30; // pause between pieces
  Future<void> _writeQueue = Future.value(); // NEW: keeps two writes from interleaving

  bool _isScanning = false;
  bool _isConnecting = false;
  bool _manualDisconnect = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;
  Timer? _reconnectTimer;
  StreamSubscription? _adapterStateSubscription;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration scanSafetyTimeout = Duration(seconds: 16);

  bool get isConnected => _connection != null && _connection!.isConnected;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isReceivingMessage => _isReceivingMessage;
  DateTime? get lastActivity => _lastActivity;
  StreamSubscription<classic.BluetoothDiscoveryResult>? _scanSubscription;

  Future<void> initializeClassicService({MqttPayloadProvider? state}) async {
    providerState = state;

    // Let the coordinator fully stop us (not just pause scanning) if
    // the other stack needs the radio.
    BluetoothActivityCoordinator.instance.onPauseClassic = () {
      hardStop();
    };

    // Watch adapter state so the UI can react if Bluetooth is turned off mid-use,
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

  // ===========================================================================
  // SCAN
  // ===========================================================================

  /// Scans for classic Bluetooth devices matching [deviceId].
  Future<void> scanDevices(String deviceId) async {
    if (_isScanning) {
      debugPrint("⚠️ Classic scan already in progress");
      return;
    }

    // Make sure BLE isn't mid-scan/connect on the same radio.
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

  // ===========================================================================
  // CONNECT
  // ===========================================================================

  /// Connects to a classic device.
  Future<void> connectToDevice(ClassicBluetoothDeviceModel device) async {
    if (_isConnecting) {
      debugPrint("⚠️ Classic connection already in progress");
      return;
    }

    // Already connected to this exact device — just confirm state to the UI.
    if (isConnected && _connectedAddress == device.device.address) {
      debugPrint("✅ Classic already connected to ${device.device.address} — skipping reconnect");
      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.connected.index);
      providerState?.updateClassicConnectedDeviceStatus(device);
      return;
    }

    _isConnecting = true;
    _manualDisconnect = false;

    // Make sure BLE isn't mid-scan/connect on the same radio.
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

      // Only close the existing connection if it's to a *different* device.
      if (isConnected) {
        debugPrint("🔌 Switching devices — closing existing classic connection first");
        await disconnect();
      }

      // Ensure the device is bonded at the OS level before opening an SPP socket.
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
        debugPrint("⚠️ Bond-state check not available/failed: $e");
      }

      _connectedAddress = device.device.address;
      _connectedDeviceRef = device.device;

      // Make sure discovery is truly stopped and the radio has settled
      // before opening the RFCOMM socket.
      try {
        await classic.FlutterBluetoothSerial.instance.cancelDiscovery();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 600));

      final connection = await _connectWithSingleRetry(device.device.address);
      _connection = connection;
      _reconnectAttempts = 0;
      _lastActivity = DateTime.now();
      _clearBufferState();

      providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.connected.index);
      providerState?.updateClassicConnectedDeviceStatus(device);

      // Incoming data goes straight to the response handler (see RESPONSE section).
      await _inputSubscription?.cancel();
      _inputSubscription = connection.input?.listen(
        _onDataReceived,
        onError: (e) => debugPrint("❌ Classic input stream error: $e"),
        onDone: () {
          final wasConnected = _connection != null;
          _connection = null;
          _inputSubscription = null;
          _clearBufferState();
          providerState?.updateClassicDeviceStatus(device.device.address, BlueConnectionState.disconnected.index);
          providerState?.updateClassicConnectedDeviceStatus(null);

          if (wasConnected && !_manualDisconnect) {
            onConnectionError?.call("Device is disconnected");
            _attemptReconnect(device);
          }
        },
      );

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
      // Release the radio claim once the connect attempt is resolved.
      BluetoothActivityCoordinator.instance.release(BluetoothStack.classic);
    }
  }

  // The first classic connect() after a scan/pairing very commonly fails
  // with "read failed, socket might closed or timeout" because Android's SDP
  // cache isn't warm yet. A single immediate retry resolves this most of the time.
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

  /// Fully tears this stack down — stops discovery, cancels the reconnect
  /// loop, and closes any live connection. Safe to call when nothing is connected.
  Future<void> hardStop() async {
    debugPrint("🛑 Classic hardStop — releasing radio for other stack");
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    await stopDiscovery();
    await _inputSubscription?.cancel();
    _inputSubscription = null;
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
    _clearBufferState();
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

  // ===========================================================================
  // RESPONSE (incoming data) — kept separate from the write path
  //
  //   _onDataReceived        raw bytes -> text
  //   _handleDeviceResponse  buffer handling (stale timer, new-message reset)
  //   _handleTraceLogData    trace-log traffic only
  //   _parseBuffer           framing:  *<payload+crc>#   or   *Start{json}#End
  //   _processData           JSON -> provider updates
  // ===========================================================================

  void _onDataReceived(Uint8List data) {
    // allowMalformed: a chunk can end in the middle of a multi-byte character
    final response = utf8.decode(data, allowMalformed: true);
    debugPrint("📩 Classic RAW DATA length: ${data.length}");
    _handleDeviceResponse(response);
  }

  void _handleDeviceResponse(String response) {
    debugPrint("📱 Processing classic device response: $response");
    _lastActivity = DateTime.now();
    _isReceivingMessage = true;

    // Trace-log traffic is handled on its own and never goes into the JSON buffer.
    if (_handleTraceLogData(response)) {
      _isReceivingMessage = false;
      return;
    }

    // A new message started while the old buffer was incomplete -> drop the stale part.
    if (response.isNotEmpty && response[0] == '*' && _buffer.isNotEmpty) {
      debugPrint("⚠️ New message started while old buffer was incomplete — discarding stale buffer");
      _buffer = '';
    }

    _buffer += response;

    _bufferStaleTimer?.cancel();
    _bufferStaleTimer = Timer(const Duration(milliseconds: bufferStaleTimeoutMS), () {
      if (_buffer.isNotEmpty) {
        debugPrint("⏱️ Classic buffer stale — clearing: $_buffer");
        _buffer = '';
      }
      _isReceivingMessage = false;
    });

    _parseBuffer();
  }

  /// Returns true when [chunk] belonged to a trace-log transfer.
  /// Works on the incoming chunk only, so nothing is appended twice.
  bool _handleTraceLogData(String chunk) {
    final sizeMatch = RegExp(r'LogFileSize:(\d+)').firstMatch(chunk);
    if (sizeMatch != null) {
      providerState?.setTotalTraceSize(int.tryParse(sizeMatch.group(1) ?? '0') ?? 0);
    }

    final bool hasStart = chunk.contains('*StartLog');
    final bool hasEnd = chunk.contains('LogFileSentSuccess');
    final bool wasLogging = isLogging;

    if (hasStart) {
      isLogging = true;
      traceChunk = chunk.substring(chunk.indexOf('*StartLog'));
    } else if (isLogging) {
      traceChunk += chunk;
    }

    if (isLogging) {
      providerState?.setTraceLoading(true);
      providerState?.setTraceLoadingsize(getCurrentChunkSize());
    }

    if (hasEnd && traceChunk.isNotEmpty) {
      isLogging = false;
      traceLog.add(traceChunk);
      providerState?.updateTraceLogs(traceLog);
      providerState?.setTraceLoading(false);

      final int sizeInBytes = getTraceLogSize();
      debugPrint('TraceLog size in bytes: $sizeInBytes');
      providerState?.setTraceLoadingsize(sizeInBytes);

      traceChunk = '';
    }

    return hasStart || hasEnd || wasLogging;
  }

  void _parseBuffer() {
    debugPrint('Classic _buffer----> $_buffer');
    if (_buffer.isEmpty) return;

    // 1) CRC framed message:  *<payload+crc>#
    //    ('*Start...' is the older framing and is handled below.)
    if (_buffer[0] == '*' && !_buffer.startsWith('*Start') && _buffer[_buffer.length - 1] == '#') {
      final sliced = _buffer.substring(1, _buffer.length - 1);
      debugPrint("sliced : $sliced");

      final result = Constants.validatePayloadWithCrc(sliced);
      debugPrint("classic result => $result");

      if (result != null) {
        _processData(result);
        _isReceivingMessage = false;
      } else {
        debugPrint('⚠️ CRC mismatch — likely dropped packet(s). Discarding buffer.');
      }
      _buffer = '';
    }

    // 2) Older framing:  *Start{json}#End
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

    if (_buffer.isEmpty) {
      _isReceivingMessage = false;
    }
  }

  void _processData(String jsonString) {
    debugPrint("Classic _processData call $jsonString");
    try {
      final data = json.decode(jsonString);
      final jsonStr = json.encode(data);

      // Same hand-off the BLE service does.
      MqttService().onMqttPayloadReceived(jsonString);
      providerState?.updateReceivedPayload(jsonStr, false);

      switch (data['mC'].toString()) {
        case '7300':
          _handleWifiInfo(data);
          break;
        case '4200':
          _handleWifiUpdateResponse(data);
          break;
        case '6600':
          providerState?.updateReceivedPayload(jsonStr, false);
          break;
        default:
          providerState?.updateReceivedPayload(jsonStr, true);
          break;
      }
    } catch (e) {
      debugPrint("Error parsing classic JSON: $e");
    }
  }

  // ---- 7300 : wifi list / status / interface / ip ----
  void _handleWifiInfo(dynamic data) {
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
  }

  // ---- 4200 : result of a wifi update command ----
  void _handleWifiUpdateResponse(dynamic data) {
    final entry = data['cM']?.entries.first.value;
    final code = entry?['Code']?.toString();
    // 'Message' is what the older firmware sent; 'Name' is the newer format
    final name = (entry?['Name'] ?? entry?['Message'])?.toString().trim() ?? '';

    debugPrint("📱 WiFi Response - Code: $code, Name: $name");

    final isFormatError = code == '2';
    if (isFormatError) {
      debugPrint("⚠️ Ignoring malformed-command error — not shown to user");
      return;
    }

    final isSuccess = name.toUpperCase().startsWith('SUCCESS');
    final cleanMessage = name.contains(':') ? name.split(':').skip(1).join(':').trim() : name;
    final displayMessage = cleanMessage.isNotEmpty ? cleanMessage : name;

    providerState?.updateWifiMessage(displayMessage);
    onWifiUpdateResult?.call(displayMessage, isSuccess);
    debugPrint("📢 Display Message: ${isSuccess ? '✅' : '❌'} $displayMessage");
  }

  void _clearBufferState() {
    _bufferStaleTimer?.cancel();
    _bufferStaleTimer = null;
    _buffer = '';
    _isReceivingMessage = false;
  }

  // ===========================================================================
  // WRITE (outgoing data) — small pieces, step by step
  // ===========================================================================

  /// Runs write tasks one after another so two payloads never interleave
  /// their pieces on the wire.
  Future<T> _enqueueWrite<T>(Future<T> Function() task) {
    final result = _writeQueue.then((_) => task());
    _writeQueue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// Sends `*payload#\r\n` in pieces of [writeChunkSize] bytes, waiting for
  /// each piece to be sent before the next one. Retries the whole payload up
  /// to [maxRetries] times. Returns true when the full payload was sent.
  Future<bool> write(String payload, {bool silent = false, int maxRetries = 3}) {
    return _enqueueWrite(() => _writeInternal(payload, silent, maxRetries));
  }

  Future<bool> _writeInternal(String payload, bool silent, int maxRetries) async {
    if (!isConnected) {
      if (!silent) debugPrint("❌ Classic device not connected");
      return false;
    }

    final finalPayload = '*$payload#';
    final bytes = utf8.encode('$finalPayload\r\n');
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        if (!silent) debugPrint("📤 [Classic] Sending: $finalPayload (Attempt ${attempts + 1})");

        for (int i = 0; i < bytes.length; i += writeChunkSize) {
          final conn = _connection;
          if (conn == null || !conn.isConnected) {
            throw StateError('Classic connection closed while writing');
          }

          final end = math.min(i + writeChunkSize, bytes.length);
          conn.output.add(Uint8List.fromList(bytes.sublist(i, end)));
          await conn.output.allSent; // wait until this piece is really sent
          await Future.delayed(const Duration(milliseconds: writeChunkDelayMs));
        }

        if (!silent) debugPrint("✅ [Classic] Sent successfully");
        _lastActivity = DateTime.now();
        return true;
      } catch (e) {
        attempts++;
        if (!silent) debugPrint("❌ [Classic] Write Error (Attempt $attempts): $e");

        if (!isConnected) break; // no point retrying on a closed socket
        if (attempts < maxRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    if (!silent) debugPrint("❌ [Classic] Failed to write after $maxRetries attempts");
    return false;
  }

  /// Firmware bytes are sent as they are (no *...# wrapping), but still go
  /// through the write queue so they never mix with a payload write.
  Future<void> writeFW(List<int> data) {
    return _enqueueWrite(() async {
      final conn = _connection;
      if (conn != null && conn.isConnected) {
        debugPrint("Sending ${data.length} bytes over Bluetooth...");
        conn.output.add(Uint8List.fromList(data));
        await conn.output.allSent;
        _lastActivity = DateTime.now();
      } else {
        debugPrint("Not connected");
      }
    });
  }

  // ===========================================================================
  // DISCONNECT / CLEANUP
  // ===========================================================================

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _lastActivity = null;
    _clearBufferState();
    try {
      await _inputSubscription?.cancel();
      _inputSubscription = null;
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
    _inputSubscription?.cancel();
    _inputSubscription = null;
    try {
      _connection?.close();
    } catch (_) {}
    _connection = null;
    _connectedAddress = null;
    _connectedDeviceRef = null;
    _lastActivity = null;
    _clearBufferState();
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
    onWifiUpdateResult = null;
  }

  // Backed by the reference captured at connect time (no unsafe firstWhere).
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
}*/
