
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

  factory BluetoothClassicService() {
    _instance ??= BluetoothClassicService._internal();
    return _instance!;
  }


  Future<bool> ensureBluetoothEnabled() async {
    final bluetooth = classic.FlutterBluetoothSerial.instance;

    final state = await bluetooth.state;

    if (state == classic.BluetoothState.STATE_ON) {
      return true;
    }

    // Ask Android to enable Bluetooth.
    final enabled = await bluetooth.requestEnable();

    return enabled == true;
  }

// ============================================================
// CALLBACKS
// ============================================================

  VoidCallback? onDeviceFound;
  Function()? onNoDeviceFound;
  Function(String message)? onConnectionError;
  Function(String message)? onBluetoothDisabled;
  Function(String message, bool success)? onWifiUpdateResult;

// ============================================================
// BLUETOOTH STATE
// ============================================================

  final classic.FlutterBluetoothSerial _bluetooth =
      classic.FlutterBluetoothSerial.instance;

  final List<classic.BluetoothDevice> _devices = [];

  classic.BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSubscription;
  StreamSubscription<classic.BluetoothDiscoveryResult>? _scanSubscription;
  StreamSubscription? _adapterStateSubscription;

  String? _connectedAddress;
  classic.BluetoothDevice? _connectedDeviceRef;

  MqttPayloadProvider? providerState;

  bool _isScanning = false;
  bool _isConnecting = false;
  bool _manualDisconnect = false;

  int _reconnectAttempts = 0;

  static const int maxReconnectAttempts = 3;

  Timer? _reconnectTimer;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration scanSafetyTimeout = Duration(seconds: 16);

  bool get isConnected =>
      _connection != null && _connection!.isConnected;

  bool get isScanning => _isScanning;

  bool get isConnecting => _isConnecting;

  bool get isReceivingMessage => _isReceivingMessage;

  DateTime? get lastActivity => _lastActivity;

  classic.BluetoothDevice? get connectedDevice => _connectedDeviceRef;

// ============================================================
// RESPONSE BUFFER
// ============================================================

  String _buffer = '';

  Timer? _bufferStaleTimer;

  static const int bufferStaleTimeoutMS = 5000;

  bool _isReceivingMessage = false;

  DateTime? _lastActivity;

// ============================================================
// TRACE LOG
// ============================================================

  List<String> traceLog = [];

  bool isLogging = false;

  String traceChunk = '';

  int getTraceLogSize() {
    var totalBytes = 0;

    for (final str in traceLog) {
      totalBytes += utf8.encode(str).length;
    }

    return totalBytes;
  }

  int getCurrentChunkSize() {
    return utf8.encode(traceChunk).length;
  }

// ============================================================
// WRITE SETTINGS
// ============================================================

  static const int writeChunkSize = 20;

  static const int writeChunkDelayMs = 30;

  Future<void> _writeQueue = Future.value();

// ============================================================
// INITIALIZATION
// ============================================================

  Future<void> initializeClassicService({
    MqttPayloadProvider? state,
  }) async {
    providerState = state;

    BluetoothActivityCoordinator.instance.onPauseClassic = () {
      hardStop();
    };

// Prevent duplicate adapter listeners if initialization is repeated.
    await _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;

    try {
      _adapterStateSubscription =
          _bluetooth.onStateChanged().listen((state) {
            debugPrint('🔵 Classic Bluetooth State: $state');

            if (state == classic.BluetoothState.STATE_OFF) {
              _resetConnection();

              providerState?.updateClassicConnectedDeviceStatus(null);

              onBluetoothDisabled?.call(
                'Bluetooth was turned off. Please turn it back on to continue.',
              );
            }
          });
    } catch (e) {
      debugPrint(
        '⚠️ Could not listen to classic adapter state: $e',
      );
    }
  }

  Future<void> initPermissions() async {
    try {
      final isEnabled = await _bluetooth.isEnabled;

      if (!(isEnabled ?? false)) {
        await _bluetooth.requestEnable();
      }

      final enabledAfterRequest = await _bluetooth.isEnabled;

      if (!(enabledAfterRequest ?? false)) {
        debugPrint('⚠️ Bluetooth is still disabled.');
      }
    } catch (e) {
      debugPrint('⚠️ Error enabling Bluetooth: $e');
    }
  }

// ============================================================
// PERMISSIONS
//
// Android 12+:
//   - BLUETOOTH_CONNECT for connecting.
//   - BLUETOOTH_SCAN for discovery.
//   - Location is not forced just to connect.
//
// Android 11 and below:
//   - Bluetooth permission for Classic Bluetooth.
//   - Location permission for discovery.
// ============================================================

  Future<bool> requestPermissions({
    bool forScan = false,
  }) async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      final List<Permission> permissions = [];

      if (sdkInt >= 31) {
        permissions.add(Permission.bluetoothConnect);

        if (forScan) {
          permissions.add(Permission.bluetoothScan);
        }
      } else {
        permissions.add(Permission.bluetooth);

        if (forScan) {
          permissions.add(Permission.locationWhenInUse);
        }
      }

      if (permissions.isEmpty) {
        return true;
      }

      final statuses = await permissions.request();

      for (final entry in statuses.entries) {
        final status = entry.value;

        if (status.isDenied ||
            status.isPermanentlyDenied ||
            status.isRestricted) {
          debugPrint(
            '❌ Bluetooth permission not granted: '
                '${entry.key} => $status',
          );

          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint(
        '⚠️ Error requesting Classic Bluetooth permissions: $e',
      );

      return false;
    }
  }

  Future<void> checkLocationServices() async {
    try {
      final isLocationEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!isLocationEnabled) {
        debugPrint(
          '⚠️ Location services are OFF. '
              'Opening location settings for discovery.',
        );

        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      debugPrint('⚠️ Error checking location services: $e');
    }
  }

// ============================================================
// SCAN
// ============================================================

  Future<void> scanDevices(String deviceId) async {

    final enabled = await ensureBluetoothEnabled();

    if (!enabled) {
      debugPrint('Bluetooth is disabled or permission was denied.');
      return;
    }

    if (_isScanning) {
      debugPrint('⚠️ Classic scan already in progress.');
      return;
    }

    var coordinatorClaimed = false;

    try {
      await BluetoothActivityCoordinator.instance.claim(
        BluetoothStack.classic,
      );

      coordinatorClaimed = true;

      final permissionsGranted = await requestPermissions(
        forScan: true,
      );

      if (!permissionsGranted) {
        onConnectionError?.call(
          'Bluetooth scan permissions are required. '
              'Please grant the requested permissions and try again.',
        );

        return;
      }

// Location is only checked here for discovery, not connection.
      if (Platform.isAndroid) {
        await checkLocationServices();
      }

      _devices.clear();

      try {
        providerState?.updateClassicPairedDevices([]);
      } catch (e) {
        debugPrint(
          '⚠️ Error clearing Classic provider devices: $e',
        );
      }

      await _scanSubscription?.cancel();
      _scanSubscription = null;

      try {
        await _bluetooth.cancelDiscovery();
      } catch (e) {
        debugPrint('⚠️ Cancel discovery before scan: $e');
      }

      _isScanning = true;

      final completer = Completer<void>();

      _scanSubscription = _bluetooth.startDiscovery().listen(
            (result) {
          final device = result.device;

          if (!(device.name?.contains(deviceId) ?? false)) {
            return;
          }

          final exists = _devices.any(
                (d) => d.address == device.address,
          );

          if (!exists) {
            _devices.add(device);

            final existing =
            providerState?.pairedDevicesClassic.firstWhere(
                  (e) => e.device.address == device.address,
              orElse: () => ClassicBluetoothDeviceModel(
                device: device,
              ),
            );

            final updatedDevice = ClassicBluetoothDeviceModel(
              device: device,
              connectionState: existing?.connectionState ??
                  BlueConnectionState.disconnected,
            );

            final updatedList = [
              ...(providerState?.pairedDevicesClassic.where(
                    (d) => d.device.address != device.address,
              ) ??
                  <ClassicBluetoothDeviceModel>[]),
              updatedDevice,
            ];

            providerState?.updateClassicPairedDevices(
              updatedList,
            );
          }

          onDeviceFound?.call();
        },
        onError: (Object e, StackTrace stackTrace) {
          debugPrint('❌ Classic discovery stream error: $e');
          debugPrintStack(stackTrace: stackTrace);

          onConnectionError?.call(
            'Bluetooth scan failed: $e',
          );

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        cancelOnError: true,
      );

      try {
        await completer.future.timeout(
          scanSafetyTimeout,
          onTimeout: () {
            debugPrint('⏱️ Classic scan safety timeout reached.');
          },
        );
      } on TimeoutException {
        debugPrint('⏱️ Classic scan timed out.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error during Classic scan: $e');
      debugPrintStack(stackTrace: stackTrace);

      onConnectionError?.call(
        'Bluetooth scan failed: $e',
      );
    } finally {
      try {
        await _scanSubscription?.cancel();
      } catch (e) {
        debugPrint('⚠️ Error cancelling scan subscription: $e');
      }

      _scanSubscription = null;

      try {
        await _bluetooth.cancelDiscovery();
      } catch (e) {
        debugPrint('⚠️ Error stopping discovery: $e');
      }

      _isScanning = false;

      if (_devices.isEmpty) {
        debugPrint(
          '⚠️ Classic scan finished — no matching devices found.',
        );

        onNoDeviceFound?.call();
      }

      if (coordinatorClaimed) {
        BluetoothActivityCoordinator.instance.release(
          BluetoothStack.classic,
        );
      }
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _scanSubscription?.cancel();
    } catch (e) {
      debugPrint('⚠️ Error cancelling scan subscription: $e');
    }

    _scanSubscription = null;
    _isScanning = false;

    try {
      await _bluetooth.cancelDiscovery();
    } catch (e) {
      debugPrint('⚠️ Error cancelling Bluetooth discovery: $e');
    }
  }

  Future<void> resetBluetoothState() async {
    await stopDiscovery();

    _devices.clear();

    providerState?.updateClassicPairedDevices([]);
  }

// ============================================================
// CONNECT
//
// Important:
// - Do not bond explicitly here.
// - The device must expose a compatible Classic SPP/RFCOMM service.
// - The caller must stop BLE scanning before connecting.
// ============================================================

  Future<void> connectToDevice(
      ClassicBluetoothDeviceModel device,
      ) async {
    final address = device.device.address;

    if (_isConnecting) {
      debugPrint(
        '⚠️ Classic connection already in progress.',
      );

      return;
    }

    if (isConnected && _connectedAddress == address) {
      debugPrint(
        '✅ Already connected to $address.',
      );

      providerState?.updateClassicDeviceStatus(
        address,
        BlueConnectionState.connected.index,
      );

      providerState?.updateClassicConnectedDeviceStatus(
        device,
      );

      return;
    }

    _isConnecting = true;
    _manualDisconnect = false;

    var coordinatorClaimed = false;

    try {
      await BluetoothActivityCoordinator.instance.claim(
        BluetoothStack.classic,
      );

      coordinatorClaimed = true;

      final permissionsGranted = await requestPermissions();

      if (!permissionsGranted) {
        onConnectionError?.call(
          'Bluetooth permission is required to connect. '
              'Please grant Bluetooth access and try again.',
        );

        return;
      }

      await initPermissions();

      final bluetoothEnabled = await _bluetooth.isEnabled;

      if (!(bluetoothEnabled ?? false)) {
        throw StateError(
          'Bluetooth is disabled. Please enable Bluetooth and try again.',
        );
      }

      providerState?.updateClassicDeviceStatus(
        address,
        BlueConnectionState.connecting.index,
      );

// Close an existing connection before switching devices.
      if (_connection != null) {
        debugPrint(
          '🔌 Closing existing Classic connection before switching.',
        );

        await _closeCurrentConnection(
          manual: true,
          updateProvider: true,
        );

        _manualDisconnect = false;
      }

// Do not mark the requested device as connected before the socket
// has actually opened successfully.
      await _bluetooth.cancelDiscovery();

// Wait briefly for Android discovery to stop.
      for (var i = 0; i < 15; i++) {
        bool discovering = false;

        try {
          discovering = await _bluetooth.isDiscovering ?? false;
        } catch (e) {
          debugPrint(
            '⚠️ Could not check discovery state: $e',
          );
        }

        if (!discovering) {
          break;
        }

        await Future.delayed(
          const Duration(milliseconds: 200),
        );
      }

// Allow the Bluetooth adapter to settle after discovery.
      await Future.delayed(
        const Duration(milliseconds: 1000),
      );

      debugPrint(
        '🔵 Opening Classic RFCOMM connection to $address.',
      );

      final connection = await _connectWithRetries(address);

      if (!connection.isConnected) {
        try {
          await connection.close();
        } catch (_) {}

        throw StateError(
          'Bluetooth socket was returned but is not connected.',
        );
      }

// Install the listener before publishing the connected state.
      _connection = connection;
      _connectedAddress = address;
      _connectedDeviceRef = device.device;

      _lastActivity = DateTime.now();
      _clearBufferState();

      await _inputSubscription?.cancel();
      _inputSubscription = null;

      final input = connection.input;

      if (input != null) {
        _inputSubscription = input.listen(
          _onDataReceived,
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              '❌ Classic input stream error: $error',
            );

            debugPrintStack(stackTrace: stackTrace);

            _handleConnectionClosed(connection, device);
          },
          onDone: () {
            debugPrint(
              '🔌 Classic input stream closed for $address.',
            );

            _handleConnectionClosed(connection, device);
          },
          cancelOnError: true,
        );
      } else {
        debugPrint(
          '⚠️ Classic connection has no input stream.',
        );
      }

// The socket is now connected; update the UI/provider.
      providerState?.updateClassicDeviceStatus(
        address,
        BlueConnectionState.connected.index,
      );

      providerState?.updateClassicConnectedDeviceStatus(
        device,
      );

      _reconnectAttempts = 0;

      debugPrint(
        '✅ Classic Bluetooth connected successfully: $address',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Classic connection failed for $address: $e',
      );

      debugPrintStack(stackTrace: stackTrace);

// Remove stale connection state before updating the UI.
      await _closeCurrentConnection(
        manual: false,
        updateProvider: false,
      );

      providerState?.updateClassicDeviceStatus(
        address,
        BlueConnectionState.disconnected.index,
      );

      providerState?.updateClassicConnectedDeviceStatus(null);

      if (e is TimeoutException) {
        onConnectionError?.call(
          'Bluetooth connection timed out. '
              'Make sure the device is powered on, nearby, and not '
              'connected to another phone.',
        );
      } else {
        onConnectionError?.call(
          'Unable to connect to '
              '${device.device.name ?? address}. '
              'Check that the device is powered on and supports '
              'Bluetooth Classic SPP/RFCOMM. Details: $e',
        );
      }
    } finally {
      _isConnecting = false;

      if (coordinatorClaimed) {
        BluetoothActivityCoordinator.instance.release(
          BluetoothStack.classic,
        );
      }
    }
  }

// ============================================================
// CONNECTION RETRIES
//
// Do not wrap toAddress() with Future.timeout().
//
// Future.timeout() does not cancel the native socket operation.
// Timing out a native attempt and starting another can leave multiple
// native connection attempts competing with each other.
// ============================================================


  Future<classic.BluetoothConnection> _connectWithRetries(
      String address,
      ) async {
    debugPrint('🔵 Attempting one Classic Bluetooth connection: $address');

    try {
      final connection =
      await classic.BluetoothConnection.toAddress(address);

      if (!connection.isConnected) {
        await connection.close();
        throw StateError('Bluetooth socket is not connected.');
      }

      debugPrint('✅ Classic Bluetooth connected: $address');
      return connection;
    } catch (error, stackTrace) {
      debugPrint('❌ Classic Bluetooth connection failed: $error');

      Error.throwWithStackTrace(error, stackTrace);
    }
  }


// ============================================================
// INPUT STREAM CLOSED
// ============================================================

  void _handleConnectionClosed(
      classic.BluetoothConnection connection,
      ClassicBluetoothDeviceModel device,
      ) {
// An old stream may close after a newer connection has succeeded.
// Do not clear the newer connection in that case.
    if (!identical(_connection, connection)) {
      return;
    }

    debugPrint(
      '🔌 Cleaning up closed Classic connection: '
          '${device.device.address}',
    );

    _connection = null;
    _connectedAddress = null;
    _connectedDeviceRef = null;

    _inputSubscription = null;

    _lastActivity = null;
    _clearBufferState();

    providerState?.updateClassicDeviceStatus(
      device.device.address,
      BlueConnectionState.disconnected.index,
    );

    providerState?.updateClassicConnectedDeviceStatus(null);

    if (!_manualDisconnect) {
      onConnectionError?.call(
        'Bluetooth device disconnected.',
      );

      _attemptReconnect(device);
    }
  }

// ============================================================
// AUTO RECONNECT
// ============================================================

  void _attemptReconnect(
      ClassicBluetoothDeviceModel device,
      ) {
    if (_reconnectTimer != null || _manualDisconnect) {
      return;
    }

    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint(
        '❌ Classic maximum reconnect attempts reached. '
            'Manual reconnect required.',
      );

      _reconnectAttempts = 0;
      return;
    }

    _reconnectAttempts++;

    debugPrint(
      '🔄 Classic auto-reconnect attempt '
          '$_reconnectAttempts/$maxReconnectAttempts in 5 seconds.',
    );

    _reconnectTimer = Timer(
      const Duration(seconds: 5),
          () async {
        _reconnectTimer = null;

        if (!isConnected &&
            !_isConnecting &&
            !_manualDisconnect) {
          await connectToDevice(device);
        }
      },
    );
  }

// ============================================================
// HARD STOP
// ============================================================

  Future<void> hardStop() async {
    debugPrint(
      '🛑 Classic hardStop — releasing Bluetooth radio.',
    );

    _manualDisconnect = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _reconnectAttempts = 0;

    await stopDiscovery();

    await _closeCurrentConnection(
      manual: true,
      updateProvider: true,
    );

// Do not reset this immediately; it prevents a closed input stream
// from triggering an unwanted reconnect.
    Future.delayed(
      const Duration(seconds: 1),
          () {
        _manualDisconnect = false;
      },
    );
  }

// ============================================================
// RESPONSE: INCOMING DATA
// ============================================================

  void _onDataReceived(Uint8List data) {
    if (data.isEmpty) {
      return;
    }

    final response = utf8.decode(
      data,
      allowMalformed: true,
    );

    debugPrint(
      '📩 Classic RAW DATA length: ${data.length}',
    );

    _handleDeviceResponse(response);
  }

  void _handleDeviceResponse(String response) {
    debugPrint(
      '📱 Processing Classic device response: $response',
    );

    _lastActivity = DateTime.now();
    _isReceivingMessage = true;

    if (_handleTraceLogData(response)) {
      _isReceivingMessage = false;
      return;
    }

    if (response.isNotEmpty &&
        response[0] == '*' &&
        _buffer.isNotEmpty) {
      debugPrint(
        '⚠️ New message started while old buffer was incomplete. '
            'Discarding stale buffer.',
      );

      _buffer = '';
    }

    _buffer += response;

    _bufferStaleTimer?.cancel();

    _bufferStaleTimer = Timer(
      const Duration(milliseconds: bufferStaleTimeoutMS),
          () {
        if (_buffer.isNotEmpty) {
          debugPrint(
            '⏱️ Classic buffer stale — clearing: $_buffer',
          );

          _buffer = '';
        }

        _isReceivingMessage = false;
      },
    );

    _parseBuffer();
  }

// ============================================================
// TRACE LOG PROCESSING
// ============================================================

  bool _handleTraceLogData(String chunk) {
    final sizeMatch =
    RegExp(r'LogFileSize:(\d+)').firstMatch(chunk);

    if (sizeMatch != null) {
      providerState?.setTotalTraceSize(
        int.tryParse(sizeMatch.group(1) ?? '0') ?? 0,
      );
    }

    final hasStart = chunk.contains('*StartLog');
    final hasEnd = chunk.contains('LogFileSentSuccess');
    final wasLogging = isLogging;

    if (hasStart) {
      isLogging = true;

      traceChunk = chunk.substring(
        chunk.indexOf('*StartLog'),
      );
    } else if (isLogging) {
      traceChunk += chunk;
    }

    if (isLogging) {
      providerState?.setTraceLoading(true);

      providerState?.setTraceLoadingsize(
        getCurrentChunkSize(),
      );
    }

    if (hasEnd && traceChunk.isNotEmpty) {
      isLogging = false;

      traceLog.add(traceChunk);

      providerState?.updateTraceLogs(traceLog);
      providerState?.setTraceLoading(false);

      final sizeInBytes = getTraceLogSize();

      debugPrint(
        'TraceLog size in bytes: $sizeInBytes',
      );

      providerState?.setTraceLoadingsize(
        sizeInBytes,
      );

      traceChunk = '';
    }

    return hasStart || hasEnd || wasLogging;
  }

// ============================================================
// MESSAGE PARSING
// ============================================================

  void _parseBuffer() {
    debugPrint(
      'Classic _buffer----> $_buffer',
    );

    if (_buffer.isEmpty) {
      return;
    }

    if (_buffer[0] == '*' &&
        !_buffer.startsWith('*Start') &&
        _buffer[_buffer.length - 1] == '#') {
      final sliced = _buffer.substring(
        1,
        _buffer.length - 1,
      );

      debugPrint('sliced : $sliced');

      final result = Constants.validatePayloadWithCrc(
        sliced,
      );

      debugPrint(
        'classic result => $result',
      );

      if (result != null) {
        _processData(result);
        _isReceivingMessage = false;
      } else {
        debugPrint(
          '⚠️ CRC mismatch — discarding buffer.',
        );
      }

      _buffer = '';
    }

    while (_buffer.contains('*Start') &&
        _buffer.contains('#End')) {
      final start = _buffer.indexOf('*Start');
      final end = _buffer.indexOf('#End', start);

      if (start != -1 && end != -1 && end > start) {
        final jsonString = _buffer
            .substring(start + 6, end)
            .trim();

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
    debugPrint(
      'Classic _processData call $jsonString',
    );

    try {
      final data = json.decode(jsonString);
      final jsonStr = json.encode(data);

      MqttService().onMqttPayloadReceived(jsonString);

      providerState?.updateReceivedPayload(
        jsonStr,
        false,
      );

      switch (data['mC'].toString()) {
        case '7300':
          _handleWifiInfo(data);
          break;

        case '4200':
          _handleWifiUpdateResponse(data);
          break;

        case '6600':
          providerState?.updateReceivedPayload(
            jsonStr,
            false,
          );
          break;

        default:
          providerState?.updateReceivedPayload(
            jsonStr,
            true,
          );
          break;
      }
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Error parsing Classic JSON: $e',
      );

      debugPrintStack(stackTrace: stackTrace);
    }
  }

// ============================================================
// WIFI INFORMATION
// ============================================================

  void _handleWifiInfo(dynamic data) {
    final rawList = data['cM']?['7301']?['ListOfWifi'];
    final wifiStatus = data['cM']?['7301']?['Status'];
    final interfaceType = data['cM']?['7301']?['InterfaceType'];
    final ipAddress = data['cM']?['7301']?['IpAddress'];

    providerState?.updateWifiStatus(
      wifiStatus,
      false,
    );

    providerState?.updateInterfaceType(
      interfaceType,
    );

    providerState?.updateIpAddress(
      ipAddress,
    );

    if (rawList is List) {
      final wifiList = rawList
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e),
      )
          .toList();

      providerState?.updateWifiList(
        wifiList,
      );
    }
  }

// ============================================================
// WIFI UPDATE RESPONSE
// ============================================================

  void _handleWifiUpdateResponse(dynamic data) {
    final entry = data['cM']?.entries.first.value;

    final code = entry?['Code']?.toString();

    final name =
        (entry?['Name'] ?? entry?['Message'])
            ?.toString()
            .trim() ??
            '';

    debugPrint(
      '📱 WiFi Response - Code: $code, Name: $name',
    );

    final isFormatError = code == '2';

    if (isFormatError) {
      debugPrint(
        '⚠️ Ignoring malformed-command error.',
      );

      return;
    }

    final isSuccess =
    name.toUpperCase().startsWith('SUCCESS');

    final cleanMessage = name.contains(':')
        ? name.split(':').skip(1).join(':').trim()
        : name;

    final displayMessage =
    cleanMessage.isNotEmpty ? cleanMessage : name;

    providerState?.updateWifiMessage(
      displayMessage,
    );

    onWifiUpdateResult?.call(
      displayMessage,
      isSuccess,
    );

    debugPrint(
      '📢 Display Message: '
          '${isSuccess ? '✅' : '❌'} $displayMessage',
    );
  }

// ============================================================
// BUFFER CLEANUP
// ============================================================

  void _clearBufferState() {
    _bufferStaleTimer?.cancel();
    _bufferStaleTimer = null;

    _buffer = '';
    _isReceivingMessage = false;
  }

// ============================================================
// WRITE QUEUE
// ============================================================

  Future<T> _enqueueWrite<T>(
      Future<T> Function() task,
      ) {
    final result = _writeQueue.then(
          (_) => task(),
    );

    _writeQueue = result.then<void>(
          (_) {},
      onError: (_) {},
    );

    return result;
  }

  Future<bool> write(
      String payload, {
        bool silent = false,
        int maxRetries = 3,
      }) {
    return _enqueueWrite(
          () => _writeInternal(
        payload,
        silent,
        maxRetries,
      ),
    );
  }

  Future<bool> _writeInternal(
      String payload,
      bool silent,
      int maxRetries,
      ) async {
    if (!isConnected) {
      if (!silent) {
        debugPrint(
          '❌ Classic device not connected.',
        );
      }

      return false;
    }

    if (maxRetries <= 0) {
      return false;
    }

    final finalPayload = '*$payload#';

    final bytes = utf8.encode(
      '$finalPayload\r\n',
    );

    var attempts = 0;

    while (attempts < maxRetries) {
      try {
        if (!silent) {
          debugPrint(
            '📤 [Classic] Sending: $finalPayload '
                '(Attempt ${attempts + 1})',
          );
        }

        for (var i = 0; i < bytes.length; i += writeChunkSize) {
          final conn = _connection;

          if (conn == null || !conn.isConnected) {
            throw StateError(
              'Classic connection closed while writing.',
            );
          }

          final end = math.min(
            i + writeChunkSize,
            bytes.length,
          );

          conn.output.add(
            Uint8List.fromList(
              bytes.sublist(i, end),
            ),
          );

          await conn.output.allSent;

          await Future.delayed(
            const Duration(milliseconds: writeChunkDelayMs),
          );
        }

        if (!silent) {
          debugPrint(
            '✅ [Classic] Sent successfully.',
          );
        }

        _lastActivity = DateTime.now();

        return true;
      } catch (e) {
        attempts++;

        if (!silent) {
          debugPrint(
            '❌ [Classic] Write error '
                '(Attempt $attempts): $e',
          );
        }

        if (!isConnected) {
          break;
        }

        if (attempts < maxRetries) {
          await Future.delayed(
            const Duration(milliseconds: 500),
          );
        }
      }
    }

    if (!silent) {
      debugPrint(
        '❌ [Classic] Failed to write after $maxRetries attempts.',
      );
    }

    return false;
  }

  Future<void> writeFW(List<int> data) {
    return _enqueueWrite(() async {
      final conn = _connection;

      if (conn != null && conn.isConnected) {
        debugPrint(
          'Sending ${data.length} bytes over Bluetooth.',
        );

        conn.output.add(
          Uint8List.fromList(data),
        );

        await conn.output.allSent;

        _lastActivity = DateTime.now();
      } else {
        debugPrint(
          '❌ Cannot send firmware data: not connected.',
        );
      }
    });
  }

// ============================================================
// DISCONNECT
// ============================================================

  Future<void> disconnect() async {
    debugPrint('🔌 Manual Classic disconnect requested.');

    _manualDisconnect = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _reconnectAttempts = 0;

    await _closeCurrentConnection(
      manual: true,
      updateProvider: true,
    );

    Future.delayed(
      const Duration(seconds: 2),
          () {
        _manualDisconnect = false;
      },
    );
  }

// ============================================================
// CONNECTION CLEANUP
// ============================================================

  Future<void> _closeCurrentConnection({
    required bool manual,
    required bool updateProvider,
  }) async {
    if (manual) {
      _manualDisconnect = true;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final oldConnection = _connection;
    final oldAddress = _connectedAddress;

    _connection = null;
    _connectedAddress = null;
    _connectedDeviceRef = null;

    _lastActivity = null;

    _clearBufferState();

    try {
      await _inputSubscription?.cancel();
    } catch (e) {
      debugPrint(
        '⚠️ Error cancelling Classic input subscription: $e',
      );
    } finally {
      _inputSubscription = null;
    }

    if (oldConnection != null) {
      try {
        await oldConnection.close();
      } catch (e) {
        debugPrint(
          '⚠️ Error closing Classic connection: $e',
        );
      }
    }

    if (updateProvider) {
      if (oldAddress != null) {
        providerState?.updateClassicDeviceStatus(
          oldAddress,
          BlueConnectionState.disconnected.index,
        );
      }

      providerState?.updateClassicConnectedDeviceStatus(
        null,
      );
    }
  }

// ============================================================
// RESET CONNECTION
// ============================================================

  void _resetConnection() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final oldConnection = _connection;

    _connection = null;
    _connectedAddress = null;
    _connectedDeviceRef = null;

    _lastActivity = null;

    _clearBufferState();

    final oldSubscription = _inputSubscription;

    _inputSubscription = null;

    if (oldSubscription != null) {
      unawaited(
        oldSubscription.cancel().catchError((Object e) {
          debugPrint(
            '⚠️ Error cancelling input during reset: $e',
          );
        }),
      );
    }

    if (oldConnection != null) {
      unawaited(
        oldConnection.close().catchError((Object e) {
          debugPrint(
            '⚠️ Error closing connection during reset: $e',
          );
        }),
      );
    }
  }

// ============================================================
// DISPOSE
// ============================================================

  Future<void> dispose() async {
    _manualDisconnect = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await stopDiscovery();

    await _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;

    await _closeCurrentConnection(
      manual: true,
      updateProvider: true,
    );

    onDeviceFound = null;
    onNoDeviceFound = null;
    onConnectionError = null;
    onBluetoothDisabled = null;
    onWifiUpdateResult = null;
  }
}


/*
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
}*/
