import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_client_factory_stub.dart'
    if (dart.library.io) 'mqtt_client_factory_io.dart'
    if (dart.library.js_interop) 'mqtt_client_factory_web.dart';
import 'package:oro_drip_irrigation/utils/environment.dart';
import 'package:uuid/uuid.dart';
import '../Constants/constants.dart';
import '../StateManagement/mqtt_payload_provider.dart';
import '../modules/PumpController/model/pump_controller_data_model.dart';
import '../utils/constants.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/my_helper_class.dart';

class MqttService {
  static MqttService? _instance;
  MqttPayloadProvider? providerState;
  MqttClient? _client;
  String? currentTopic;

  MqttService._internal();

  factory MqttService() {
    _instance ??= MqttService._internal();
    return _instance!;
  }

  // Connection State
  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;
  MqttConnectionState get mqttConnectionState => _client?.connectionStatus?.state ?? MqttConnectionState.disconnected;

  final StreamController<MqttConnectionState> _connectionController = StreamController.broadcast();
  Stream<MqttConnectionState> get mqttConnectionStream => _connectionController.stream;

  // Acknowledgement Payload
  Map<String, dynamic>? _acknowledgementPayload;
  Map<String, dynamic>? get acknowledgementPayload => _acknowledgementPayload;
  final StreamController<Map<String, dynamic>?> _acknowledgementPayloadController = StreamController.broadcast();
  Stream<Map<String, dynamic>?> get payloadController => _acknowledgementPayloadController.stream;

  // Schedule Payload
  List<Map<String, dynamic>>? _schedulePayload;
  List<Map<String, dynamic>>? get schedulePayload => _schedulePayload;

  // Use BehaviorSubject so new subscribers immediately receive the latest value
  final BehaviorSubject<List<Map<String, dynamic>>?> _schedulePayloadController =
  BehaviorSubject<List<Map<String, dynamic>>?>.seeded(null);
  Stream<List<Map<String, dynamic>>?> get schedulePayloadStream => _schedulePayloadController.stream;

  set schedulePayload(List<Map<String, dynamic>>? newPayload) {
    // Accept null to allow clearing the cache and notify listeners
    _schedulePayload = newPayload;
    _schedulePayloadController.add(_schedulePayload);
  }

  // Raw Schedule / Live Irrigation Payload (columnar Map from cM['3601'])
  Map<String, dynamic>? _rawSchedulePayload;
  Map<String, dynamic>? get rawSchedulePayload => _rawSchedulePayload;
  final BehaviorSubject<Map<String, dynamic>?> _rawSchedulePayloadController =
  BehaviorSubject<Map<String, dynamic>?>.seeded(null);
  Stream<Map<String, dynamic>?> get rawSchedulePayloadStream => _rawSchedulePayloadController.stream;

  set rawSchedulePayload(Map<String, dynamic>? newPayload) {
    _rawSchedulePayload = newPayload;
    _rawSchedulePayloadController.add(_rawSchedulePayload);
  }

  // Pump Dashboard Payload
  PumpControllerData? _pumpDashboardPayload;
  PumpControllerData? get pumpDashboardPayload => _pumpDashboardPayload;
  final BehaviorSubject<PumpControllerData?> _pumpDashboardPayloadController = BehaviorSubject<PumpControllerData?>();
  Stream<PumpControllerData?> get pumpDashboardPayloadStream => _pumpDashboardPayloadController.stream;

  StreamSubscription? _subscription;

  set pumpDashboardPayload(PumpControllerData? newPayload) {
    if (newPayload != null) {
      _pumpDashboardPayload = newPayload;
      _pumpDashboardPayloadController.add(_pumpDashboardPayload);
    }
  }

  // Preference Acknowledgement
  Map<String, dynamic>? _preferenceAck;
  Map<String, dynamic>? get preferenceAck => _preferenceAck;
  final StreamController<Map<String, dynamic>?> _ackController = StreamController.broadcast();
  Stream<Map<String, dynamic>?> get preferenceAckStream => _ackController.stream;

  set preferenceAck(Map<String, dynamic>? newPayload) {
    if (newPayload != null) {
      _preferenceAck = newPayload;
      _ackController.add(_preferenceAck);
    }
  }

  set acknowledgementPayload(Map<String, dynamic>? newPayload) {
    _acknowledgementPayload = newPayload;
    _acknowledgementPayloadController.add(_acknowledgementPayload);
  }

  void initializeMQTTClient({MqttPayloadProvider? state}) {
    providerState = state;
    final uniqueId = const Uuid().v4();

    if (_client != null) return;

    _client = createMqttClient(
      kIsWeb ? Environment.mqttWebUrl : Environment.mqttMobileUrl,
      uniqueId,
    );

    _client!
      ..keepAlivePeriod = 30
      ..logging(on: false)
      ..onDisconnected = onDisconnected
      ..onConnected = onConnected
      ..onSubscribed = onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(uniqueId)
        .authenticateAs(
      AppConstants.mqttUserName,
      AppConstants.mqttPassword,
    ).startClean();

    _client!.connectionMessage = connMess;
  }

  Future<void> connect() async {
    if (_client == null ||
        isConnected ||
        _client!.connectionStatus?.state == MqttConnectionState.connecting) {
      return;
    }

    try {
      await _client!.connect();
    } catch (e, stackTrace) {
      debugPrint('MQTT Connect Exception: $e');
      debugPrint('$stackTrace');
      _client?.disconnect();
    }
  }

  Future<void> disConnect() async {
    assert(_client != null);
    if (isConnected) {
      try {
        _client!.disconnect();
      } catch (e, stackTrace) {
        debugPrint('MQTT Disconnect Exception: $e');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> topicToSubscribe(String topic) async {
    try {
      int retries = 0;
      // Wait until real MQTT connection is ready
      while ((_client?.connectionStatus?.state !=
          MqttConnectionState.connected) &&
          retries < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
      }

      if (_client?.connectionStatus?.state !=
          MqttConnectionState.connected) {
        debugPrint('MQTT not connected. Cannot subscribe to topic: $topic');
        return;
      }

      // Unsubscribe previous topic safely
      if (currentTopic != null && currentTopic != topic) {
        _client?.unsubscribe(currentTopic!);
      }

      await _subscription?.cancel();

      _client?.subscribe(topic, MqttQos.atLeastOnce);
      currentTopic = topic;

      _subscription = _client?.updates?.listen(
            (List<MqttReceivedMessage<MqttMessage?>>? c) {
          if (c != null && c.isNotEmpty) {
            final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;

            final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
            if(pt.isNotEmpty && pt[0] =='*' && pt[pt.length-1] == '#'){
              String sliced = pt.substring(1, pt.length - 1);
              debugPrint("sliced : $sliced");
              final result = Constants.validatePayloadWithCrc(sliced);
              debugPrint("result => $result");
              if(result != null){
                onMqttPayloadReceived(result);
              }else{
                debugPrint('Crc not match....');
              }
            }else{
              onMqttPayloadReceived(pt);
            }
          }
        },
      );

      debugPrint("Subscribed to $topic");

    } catch (e, stacktrace) {
      debugPrint('MQTT subscribe error: $e\n$stacktrace');
    }
  }


  void topicToUnSubscribe(String topic) {
    if (_client == null) return;
    _subscription?.cancel();
    _subscription = null;
    if (currentTopic != null && currentTopic == topic) {
      _client!.unsubscribe(currentTopic!);
      currentTopic = null;
    } else {
      _client!.unsubscribe(topic);
    }
  }

  void onMqttPayloadReceived(String payload) {

    try {
      final payloadMessage = jsonDecode(payload);
      acknowledgementPayload = payloadMessage;

      switch (payloadMessage['mC']) {
        case 'SMS':
          preferenceAck = payloadMessage;
          break;

        case 'LD01':
          pumpDashboardPayload = PumpControllerData.fromJson(payloadMessage, "cM", 1);
          providerState?.updateLastSyncDateFromPumpControllerPayload(payload);
          break;

        case '3600':
          if (payloadMessage['cM'] != null && payloadMessage['cM']['3601'] != null) {
            rawSchedulePayload = Map<String, dynamic>.from(payloadMessage['cM']['3601']);
            schedulePayload = Constants.dataConversionForScheduleView(payloadMessage['cM']['3601']);
          }
          break;

        case '4200':
          _handleAcknowledgement(payloadMessage);
          break;

        default:
          providerState?.updateReceivedPayload(payload, true);
      }
    } catch (e, stackTrace) {
      debugPrint('MQTT Payload Parsing Error: $e\n$stackTrace');
    }
  }

  void _handleAcknowledgement(Map<String, dynamic> message) {
    final content = message['cM']?['4201'];
    final code = content?['Code'];
    final payloadCode = content?['PayloadCode'];

    if (code == "200") {
      MqttAckTracker.ackReceived(payloadCode);
    }
  }

  Future<void> topicToPublishAndItsMessage(String message, String topic) async {
    if (!isConnected) {
      debugPrint("MQTT not connected. Cannot publish. Message dropped.");
      return;
    }

    final builder = MqttClientPayloadBuilder()..addString(message);

    try {
      _client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
    } catch (e) {
      debugPrint("MQTT Publish Error: $e");
    }
  }

  void onSubscribed(String topic) {
    debugPrint('Subscribed to topic: $topic');
  }

  void onDisconnected() {
    debugPrint('MQTT disconnected');
    _connectionController.add(MqttConnectionState.disconnected);
  }

  void onConnected() {
    debugPrint('MQTT connected');
    _connectionController.add(MqttConnectionState.connected);
  }
}