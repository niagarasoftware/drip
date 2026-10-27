import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../StateManagement/customer_provider.dart';
import '../repository/repository.dart';
import '../utils/constants.dart';
import '../utils/network_utils.dart';
import '../utils/shared_preferences_helper.dart';
import 'bluetooth/bluetooth_ble_service.dart';
import 'bluetooth/bluetooth_classic_service.dart';
import 'http_service.dart';
import 'mqtt_service.dart';

class CommunicationService {
  final MqttService mqttService;
  final BluetoothClassicService blueService;
  final BluetoothBleService bleService;
  final CustomerProvider customerProvider;

  CommunicationService({
    required this.mqttService,
    required this.blueService,
    required this.bleService,
    required this.customerProvider,
  });

  Future<Map<String, bool>> sendCommand({required String serverMsg,
    required String payload}) async {
    final result = {
      'http': false,
      'mqtt': false,
      'bluetooth': false,
    };
    try {
      if (payload.isEmpty) {
        throw Exception('Payload is empty');
      }

      // Check if any Bluetooth connection is active
      final bool isBluetoothConnected = blueService.isConnected || bleService.isConnected;

      if (!isBluetoothConnected) {

        if (mqttService.isConnected) {
          try {
            final topic = '${AppConstants.publishTopic}/${customerProvider.deviceId}';
            debugPrint('Publishing to topic: $topic with payload: $payload');
            await mqttService.topicToPublishAndItsMessage(payload, topic);
            result['mqtt'] = true;
          } catch (e) {
            debugPrint('Failed to send via MQTT: $e');
          }
        }

        if (NetworkUtils.isOnline && serverMsg.isNotEmpty) {
          try {
            await sendCommandToServer(serverMsg, payload);
            result['http'] = true;
          } catch (e) {
            debugPrint('Failed to send via HTTP: $e');
          }
        }
      } else {
        debugPrint('🔵 Bluetooth is connected - Skipping web/MQTT communication');
      }

      if (blueService.isConnected) {
        debugPrint("bluetooth connected...");
        try {
          await blueService.write(payload);
          result['bluetooth'] = true;
          debugPrint('📱 Sent via Classic Bluetooth');
        } catch (e) {
          debugPrint('Failed to send via Classic Bluetooth: $e');
        }
      } else{
        debugPrint("bluetooth not connected...");
      }

      print("bleService.isConnected : ${bleService.isConnected}");

      if (bleService.isConnected) {
        debugPrint("bluetooth connected...");
        try {
          await bleService.write(payload);
          result['bluetooth'] = true;
          debugPrint('📱 Sent via BLE');
        } catch (e) {
          debugPrint('Failed to send via BLE: $e');
        }
      }

    } catch (e) {
      debugPrint('Unexpected error during sending command: $e');
    }
    return result;
  }


  Future<void> sendCommandToServer(String msg, String data) async {
    Map<String, dynamic> hardware;
    try {
      hardware = jsonDecode(data);
    } catch (e) {
      throw Exception('Invalid JSON in payload: $e');
    }

    int? userId = await PreferenceHelper.getUserId();


    final body = {
      "userId": customerProvider.customerId,
      "controllerId": customerProvider.controllerId,
      "messageStatus": msg,
      "hardware": hardware,
      "createUser": userId,
    };

    final response = await Repository(HttpService()).sendManualOperationToServer(body);

    if (response.statusCode == 200) {
      debugPrint('HTTP Response: ${response.body}');
    } else {
      debugPrint('HTTP Error (${response.statusCode}): ${response.body}');
      throw Exception('Failed to send via HTTP');
    }
  }
}
