import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';

import '../../Constants/constants.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../utils/enums.dart';

class HotspotWebSocketService {
  static HotspotWebSocketService? _instance;

  HotspotWebSocketService._internal();

  factory HotspotWebSocketService() {
    _instance ??= HotspotWebSocketService._internal();
    return _instance!;
  }

  // ============================================================
  // CALLBACKS
  // ============================================================

  VoidCallback? onConnected;
  Function(String message)? onConnectionError;
  Function(String message, bool success)? onWifiUpdateResult;

  // ============================================================
  // SETTINGS  (change to match the device firmware)
  // ============================================================

  static const String defaultHost = '192.168.4.1';
  static const int defaultPort = 81;
  static const String defaultPath = '/';

  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration pingInterval = Duration(seconds: 10);

  static const int maxReconnectAttempts = 3;
  static const int bufferStaleTimeoutMS = 5000;

  // ============================================================
  // STATE
  // ============================================================

  MqttPayloadProvider? providerState;

  /// Listen to this from the UI (ValueListenableBuilder) for status.
  final ValueNotifier<BlueConnectionState> connectionState =
  ValueNotifier(BlueConnectionState.disconnected);

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  String _host = defaultHost;
  int _port = defaultPort;
  String _path = defaultPath;

  bool _isConnecting = false;
  bool _manualDisconnect = false;
  bool _usingWifiBinding = false;

  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  String _buffer = '';
  Timer? _bufferStaleTimer;
  bool _isReceivingMessage = false;
  DateTime? _lastActivity;

  bool get isConnected =>
      _channel != null &&
          connectionState.value == BlueConnectionState.connected;

  bool get isConnecting => _isConnecting;

  bool get isReceivingMessage => _isReceivingMessage;

  DateTime? get lastActivity => _lastActivity;

  String get host => _host;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initializeHotspotService({MqttPayloadProvider? state}) async {
    providerState = state;
    debugPrint('✅ Hotspot WebSocket service initialized.');
  }

  void _setState(BlueConnectionState s) {
    if (connectionState.value != s) {
      connectionState.value = s;
    }
  }

  // ============================================================
  // JOIN THE DEVICE HOTSPOT (optional)
  //
  // Skip this if the user joins the hotspot in Android Wi-Fi
  // settings. Needs location permission and the Wi-Fi permissions
  // in AndroidManifest.xml.
  // ============================================================

  Future<bool> joinHotspot(String ssid, {String? password}) async {
    if (!Platform.isAndroid) return false;

    try {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        onConnectionError?.call(
          'Location permission is required to join the device hotspot.',
        );
        return false;
      }

      final secured = password != null && password.isNotEmpty;

      final joined = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: secured ? NetworkSecurity.WPA : NetworkSecurity.NONE,
        joinOnce: true,
        withInternet: false,
        timeoutInSeconds: 20,
      );

      if (!joined) {
        onConnectionError?.call('Could not join hotspot "$ssid".');
      }

      return joined;
    } catch (e) {
      debugPrint('❌ joinHotspot error: $e');
      onConnectionError?.call('Could not join hotspot "$ssid": $e');
      return false;
    }
  }

  // ============================================================
  // CONNECT
  // ============================================================

  /// [bindToWifi] sends this app's traffic over Wi-Fi even though the
  /// hotspot has no internet. Without it Android often routes the
  /// connection through mobile data and it fails. It is switched off
  /// again in [disconnect].
  Future<bool> connect({
    String? host,
    int? port,
    String? path,
    bool bindToWifi = true,
  }) async {
    if (_isConnecting) {
      debugPrint('⚠️ Hotspot connection already in progress.');
      return false;
    }

    if (isConnected) {
      debugPrint('✅ Hotspot WebSocket already connected.');
      return true;
    }

    _host = host ?? _host;
    _port = port ?? _port;
    _path = path ?? _path;

    _isConnecting = true;
    _manualDisconnect = false;
    _setState(BlueConnectionState.connecting);

    try {
      if (Platform.isAndroid && bindToWifi) {
        try {
          await WiFiForIoTPlugin.forceWifiUsage(true);
          _usingWifiBinding = true;
        } catch (e) {
          debugPrint('⚠️ Could not bind to Wi-Fi: $e');
        }
      }

      final uri = Uri(scheme: 'ws', host: _host, port: _port, path: _path);
      debugPrint('🌐 Connecting WebSocket: $uri');

      final channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: pingInterval,
        connectTimeout: connectTimeout,
      );

      await channel.ready;

      _channel = channel;
      _lastActivity = DateTime.now();
      _clearBufferState();

      await _subscription?.cancel();

      _subscription = channel.stream.listen(
        _onMessage,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('❌ WebSocket stream error: $error');
          _handleClosed(channel);
        },
        onDone: () {
          debugPrint('🔌 WebSocket closed.');
          _handleClosed(channel);
        },
        cancelOnError: true,
      );

      _reconnectAttempts = 0;
      _setState(BlueConnectionState.connected);
      onConnected?.call();

      debugPrint('✅ Hotspot WebSocket connected: $uri');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Hotspot WebSocket connect failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      await _closeChannel();
      await _releaseWifiBinding();
      _setState(BlueConnectionState.disconnected);

      if (!_manualDisconnect) {
        onConnectionError?.call(
          e is TimeoutException
              ? 'Connection timed out. Check that your phone is connected '
              'to the device hotspot and the device is powered on.'
              : 'Unable to connect to the device at $_host:$_port. '
              'Make sure your phone is connected to the device hotspot. '
              'Details: $e',
        );
      }

      return false;
    } finally {
      _isConnecting = false;
    }
  }

  // ============================================================
  // CONNECTION CLOSED / RECONNECT
  // ============================================================

  void _handleClosed(WebSocketChannel channel) {
    // An old socket may close after a newer one has connected.
    if (!identical(_channel, channel)) return;

    _channel = null;
    _subscription = null;
    _lastActivity = null;
    _clearBufferState();
    _setState(BlueConnectionState.disconnected);

    if (!_manualDisconnect) {
      onConnectionError?.call('Device disconnected.');
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_reconnectTimer != null || _manualDisconnect) return;

    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('❌ Hotspot: max reconnect attempts reached.');
      _reconnectAttempts = 0;
      _releaseWifiBinding();
      return;
    }

    _reconnectAttempts++;

    debugPrint(
      '🔄 Hotspot reconnect attempt $_reconnectAttempts/$maxReconnectAttempts in 5 seconds.',
    );

    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      _reconnectTimer = null;

      if (!isConnected && !_isConnecting && !_manualDisconnect) {
        final ok = await connect();
        if (!ok && !_manualDisconnect) {
          _attemptReconnect();
        }
      }
    });
  }

  // ============================================================
  // RECEIVE
  // ============================================================

  void _onMessage(dynamic message) {
    final text = message is String
        ? message
        : utf8.decode(message as List<int>, allowMalformed: true);

    if (text.isEmpty) return;

    debugPrint('📩 WebSocket RAW DATA length: ${text.length}');
    _handleDeviceResponse(text);
  }

  void _handleDeviceResponse(String response) {
    _lastActivity = DateTime.now();
    _isReceivingMessage = true;

    final trimmed = response.trim();

    // Plain JSON message: no framing needed.
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      _processData(trimmed);
      _isReceivingMessage = false;
      return;
    }

    if (response.isNotEmpty && response[0] == '*' && _buffer.isNotEmpty) {
      debugPrint('⚠️ New message started while old buffer was incomplete.');
      _buffer = '';
    }

    _buffer += response;

    _bufferStaleTimer?.cancel();
    _bufferStaleTimer = Timer(
      const Duration(milliseconds: bufferStaleTimeoutMS),
          () {
        if (_buffer.isNotEmpty) {
          debugPrint('⏱️ WebSocket buffer stale — clearing.');
          _buffer = '';
        }
        _isReceivingMessage = false;
      },
    );

    _parseBuffer();
  }

  void _parseBuffer() {
    if (_buffer.isEmpty) return;

    // CRC framed message:  *<payload+crc>#
    if (_buffer[0] == '*' &&
        !_buffer.startsWith('*Start') &&
        _buffer.trimRight().endsWith('#')) {
      final framed = _buffer.trimRight();
      final sliced = framed.substring(1, framed.length - 1);

      final result = Constants.validatePayloadWithCrc(sliced);

      if (result != null) {
        _processData(result);
        _isReceivingMessage = false;
      } else {
        debugPrint('⚠️ CRC mismatch — discarding buffer.');
      }

      _buffer = '';
    }

    // Older framing:  *Start{json}#End
    while (_buffer.contains('*Start') && _buffer.contains('#End')) {
      final start = _buffer.indexOf('*Start');
      final end = _buffer.indexOf('#End', start);

      if (start != -1 && end != -1 && end > start) {
        _processData(_buffer.substring(start + 6, end).trim());
        _buffer = _buffer.substring(end + 4);
      } else {
        break;
      }
    }

    if (_buffer.isEmpty) _isReceivingMessage = false;
  }

  void _processData(String jsonString) {
    debugPrint('Hotspot _processData call $jsonString');

    try {
      final data = json.decode(jsonString);
      final jsonStr = json.encode(data);

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
    } catch (e, stackTrace) {
      debugPrint('❌ Error parsing WebSocket JSON: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleWifiInfo(dynamic data) {
    final rawList = data['cM']?['7301']?['ListOfWifi'];
    final wifiStatus = data['cM']?['7301']?['Status'];
    final interfaceType = data['cM']?['7301']?['InterfaceType'];
    final ipAddress = data['cM']?['7301']?['IpAddress'];

    providerState?.updateWifiStatus(wifiStatus, false);
    providerState?.updateInterfaceType(interfaceType);
    providerState?.updateIpAddress(ipAddress);

    if (rawList is List) {
      final wifiList = rawList
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      providerState?.updateWifiList(wifiList);
    }
  }

  void _handleWifiUpdateResponse(dynamic data) {
    final entry = data['cM']?.entries.first.value;
    final code = entry?['Code']?.toString();
    final name = (entry?['Name'] ?? entry?['Message'])?.toString().trim() ?? '';

    if (code == '2') {
      debugPrint('⚠️ Ignoring malformed-command error.');
      return;
    }

    final isSuccess = name.toUpperCase().startsWith('SUCCESS');
    final cleanMessage =
    name.contains(':') ? name.split(':').skip(1).join(':').trim() : name;
    final displayMessage = cleanMessage.isNotEmpty ? cleanMessage : name;

    providerState?.updateWifiMessage(displayMessage);
    onWifiUpdateResult?.call(displayMessage, isSuccess);
  }

  void _clearBufferState() {
    _bufferStaleTimer?.cancel();
    _bufferStaleTimer = null;
    _buffer = '';
    _isReceivingMessage = false;
  }

  // ============================================================
  // SEND
  // ============================================================

  /// Sends `*payload#\r\n`, the same framing as the BLE and Classic
  /// services. If the firmware expects bare JSON over WebSocket,
  /// send [payload] as it is instead.
  Future<bool> write(String payload, {bool silent = false}) async {
    final channel = _channel;

    if (channel == null || !isConnected) {
      if (!silent) debugPrint('❌ Hotspot WebSocket not connected.');
      return false;
    }

    try {
      final framed = '*$payload#\r\n';

      if (!silent) debugPrint('📤 [WS] Sending: $framed');

      channel.sink.add(framed);
      _lastActivity = DateTime.now();

      return true;
    } catch (e) {
      if (!silent) debugPrint('❌ [WS] Write error: $e');
      return false;
    }
  }

  // ============================================================
  // DISCONNECT / CLEANUP
  // ============================================================

  Future<void> disconnect() async {
    debugPrint('🔌 Manual hotspot disconnect requested.');

    _manualDisconnect = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;

    await _closeChannel();
    await _releaseWifiBinding();

    _setState(BlueConnectionState.disconnected);
  }

  Future<void> _closeChannel() async {
    final channel = _channel;

    _channel = null;
    _lastActivity = null;
    _clearBufferState();

    try {
      await _subscription?.cancel();
    } catch (_) {}
    _subscription = null;

    try {
      await channel?.sink.close(ws_status.goingAway);
    } catch (_) {}
  }

  Future<void> _releaseWifiBinding() async {
    if (!_usingWifiBinding) return;

    try {
      await WiFiForIoTPlugin.forceWifiUsage(false);
    } catch (e) {
      debugPrint('⚠️ Could not release Wi-Fi binding: $e');
    }

    _usingWifiBinding = false;
  }

  Future<void> dispose() async {
    await disconnect();

    onConnected = null;
    onConnectionError = null;
    onWifiUpdateResult = null;
  }
}