// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
//
// import 'package:flutter/foundation.dart';
// import 'package:usb_serial/usb_serial.dart';
//
// import '../../Constants/constants.dart';
// import '../../StateManagement/mqtt_payload_provider.dart';
// import '../../modules/PumpController/model/pump_controller_data_model.dart';
// import 'mqtt_service.dart';
//
// class UsbSerialService {
//   static UsbSerialService? _instance;
//   UsbSerialService._internal();
//
//   factory UsbSerialService() {
//     _instance ??= UsbSerialService._internal();
//     return _instance!;
//   }
//
//   UsbPort? _port;
//   UsbDevice? _device;
//   StreamSubscription<Uint8List>? _subscription;
//
//   String _buffer = '';
//
//   MqttPayloadProvider? providerState;
//
//   bool get isConnected => _port != null;
//
//   Future<void> initialize({MqttPayloadProvider? state}) async {
//     providerState = state;
//   }
//
//   Future<List<UsbDevice>> getDevices() async {
//     final devices = await UsbSerial.listDevices();
//     debugPrint("USB Devices: $devices");
//     return devices;
//   }
//
//   Future<bool> connect(UsbDevice device) async {
//     try {
//       _device = device;
//       _port = await device.create();
//
//       if (_port == null) return false;
//
//       bool openResult = await _port!.open();
//       if (!openResult) return false;
//
//       await _port!.setDTR(true);
//       await _port!.setRTS(true);
//
//       await _port!.setPortParameters(
//         9600, // ⚠️ Match your device baud rate
//         UsbPort.DATABITS_8,
//         UsbPort.STOPBITS_1,
//         UsbPort.PARITY_NONE,
//       );
//
//       _subscription = _port!.inputStream?.listen((data) {
//         _buffer += utf8.decode(data);
//         _parseBuffer();
//       });
//
//       debugPrint("USB Connected");
//       return true;
//     } catch (e) {
//       debugPrint("USB Connection Error: $e");
//       return false;
//     }
//   }
//
//   /// ❌ DISCONNECT
//   Future<void> disconnect() async {
//     try {
//       await _subscription?.cancel();
//       await _port?.close();
//     } catch (e) {
//       debugPrint("USB Disconnect Error: $e");
//     } finally {
//       _port = null;
//       _device = null;
//     }
//   }
//
//   /// ✉️ WRITE
//   Future<void> write(String payload) async {
//     if (_port == null) return;
//
//     final finalPayload = '*$payload#\r\n';
//     debugPrint("USB Sending: $finalPayload");
//
//     await _port!.write(Uint8List.fromList(utf8.encode(finalPayload)));
//   }
//
//   /// 🔥 SAME PARSER (REUSED)
//   void _parseBuffer() {
//     if (_buffer.isEmpty) return;
//
//     // Handle *...# packets (same as Bluetooth)
//     while (_buffer.contains('*') && _buffer.contains('#')) {
//       final start = _buffer.indexOf('*');
//       final end = _buffer.indexOf('#', start);
//
//       if (start != -1 && end != -1 && end > start) {
//         final rawPacket = _buffer.substring(start + 1, end);
//
//         final result = Constants.validatePayloadWithCrc(rawPacket);
//
//         if (result != null) {
//           try {
//             final decoded = jsonDecode(result);
//
//             // ✅ SAME MQTT FLOW
//             MqttService().preferenceAck = decoded;
//             MqttService().onMqttPayloadReceived(result);
//
//           } catch (e) {
//             debugPrint("USB JSON decode error: $e");
//           }
//         }
//
//         _buffer = _buffer.substring(end + 1);
//       } else {
//         break;
//       }
//     }
//
//     // Handle *Start ... #End JSON
//     while (_buffer.contains('*Start') && _buffer.contains('#End')) {
//       final start = _buffer.indexOf('*Start');
//       final end = _buffer.indexOf('#End', start);
//
//       if (start != -1 && end != -1 && end > start) {
//         final jsonString = _buffer.substring(start + 6, end).trim();
//         _processData(jsonString);
//
//         _buffer = _buffer.substring(end + 4);
//       } else {
//         break;
//       }
//     }
//   }
//
//   /// 🔄 SAME BUSINESS LOGIC
//   void _processData(String jsonString) {
//     try {
//       final data = json.decode(jsonString);
//       final jsonStr = json.encode(data);
//
//       providerState?.updateReceivedPayload(jsonStr, false);
//
//       switch (data['mC'].toString()) {
//         case 'LD01':
//           final pumpData = PumpControllerData.fromJson(data, "cM", 1);
//
//           // 🔥 SAME STREAM AS MQTT
//           MqttService().pumpDashboardPayload = pumpData;
//
//           providerState?.updateLastSyncDateFromPumpControllerPayload(jsonStr);
//           break;
//
//         case '7300':
//           final rawList = data["cM"]?["7301"]?["ListOfWifi"];
//           final wifiStatus = data["cM"]?["7301"]?["Status"];
//           final interfaceType = data["cM"]?["7301"]?["InterfaceType"];
//           final ipAddress = data["cM"]?["7301"]?["IpAddress"];
//
//           providerState?.updateWifiStatus(wifiStatus, false);
//           providerState?.updateInterfaceType(interfaceType);
//           providerState?.updateIpAddress(ipAddress);
//
//           if (rawList is List) {
//             final wifiList = rawList
//                 .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
//                 .toList();
//
//             providerState?.updateWifiList(wifiList);
//           }
//           break;
//
//         case '4200':
//           final message = data['cM']?.entries.first.value['Message']?.trim();
//           if (message != null) {
//             providerState?.updateWifiMessage(message);
//           }
//           break;
//
//         default:
//           providerState?.updateReceivedPayload(jsonStr, true);
//           break;
//       }
//     } catch (e) {
//       debugPrint("USB Parse Error: $e");
//     }
//   }
// }