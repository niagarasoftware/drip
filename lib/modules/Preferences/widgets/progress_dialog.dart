import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:oro_drip_irrigation/modules/Preferences/state_management/preference_provider.dart';
import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../services/communication_service.dart';
import '../../../services/mqtt_service.dart';
import '../../../utils/environment.dart';

class PayloadProgressDialog extends StatefulWidget {
  final List<String> payloads;
  final String deviceId;
  final bool isToGem;
  final bool isWlc;
  final MqttService mqttService;
  final bool shouldSendFailedPayloads;

  const PayloadProgressDialog({
    super.key,
    required this.payloads,
    required this.deviceId,
    required this.isToGem,
    required this.isWlc,
    required this.mqttService,
    required this.shouldSendFailedPayloads,
  });

  @override
  State<PayloadProgressDialog> createState() => _PayloadProgressDialogState();
}

class _PayloadProgressDialogState extends State<PayloadProgressDialog> {
  late List<Map<String, dynamic>> payloadStatuses;
  bool breakLoop = false;
  bool isAllProcessed = false;
  bool isAllSent = false;
  String mqttError = '';
  bool isSending = false;

  static const Map<String, String> statusMessages = {
    "100": "Other settings",
    "200": "Voltage settings",
    "400-1": "Current settings for pump 1",
    "300-1": "Delay settings for pump 1",
    "500-1": "RTC settings for pump 1",
    "600-1": "Schedule config for pump 1",
    "400-2": "Current settings for pump 2",
    "300-2": "Delay settings for pump 2",
    "500-2": "RTC settings for pump 2",
    "600-2": "Schedule config for pump 2",
    "400-3": "Current settings for pump 3",
    "300-3": "Delay settings for pump 3",
    "500-3": "RTC settings for pump 3",
    "600-3": "Schedule config for pump 3",
    "400-4": "Current settings for pump 4",
    "300-4": "Delay settings for pump 4",
    "500-4": "RTC settings for pump 4",
    "600-4": "Schedule config for pump 4",
    "900": "Calibration settings",
    "55": "Valve settings",
    "57": "Moisture settings",
  };

  @override
  void initState() {
    super.initState();
    if(mounted){
      payloadStatuses = widget.payloads.map((payload) {
        try {
          var payloadToDecode = widget.isToGem ? payload.split('+')[4] : payload;
          var decodedData = jsonDecode(payloadToDecode);
          var key = decodedData.keys.first;

          return {
            'payload': payload,
            'status': 'Pending',
            'reference': widget.isToGem ? payload.split('+')[2] : 'Device payload',
            'selected': true,
            'key': key,
          };
        } catch (error, stackTrace) {
          print("==================== ERROR PARSING PAYLOAD ====================");
          print("Payload: $payload");
          print("Error: $error");
          print("StackTrace:\n$stackTrace");
          print("===============================================================");
          return {
            'payload': payload,
            'status': 'Failed',
            'reference': 'Invalid payload',
            'selected': false,
            'key': '0',
          };
        }
      }).toList();
    }
  }

  void _checkAllProcessed() {
    bool allProcessed = payloadStatuses.where((s) => s['selected']).every((p) => p['status'] != 'Pending');
    bool allSent = payloadStatuses.where((s) => s['selected']).every((p) => p['status'] == 'Sent');

    if(mounted){
      setState(() {
        if (allProcessed) {
          isAllProcessed = true;
          isAllSent = allSent;
        }
      });
    }
  }

  Future<void> _processPayloads() async {
    setState(() {
      isSending = true;
    });
    for (int i = 0; i < widget.payloads.length && !breakLoop; i++) {
      if (!payloadStatuses[i]['selected']) continue;
      var payload = widget.payloads[i];
      var payloadToDecode = widget.isToGem ? payload.split('+')[4] : payload;
      var decodedData = jsonDecode(payloadToDecode);
      var key = decodedData.keys.first;

      setState(() {
        payloadStatuses[i]['status'] = 'Sending';
      });

      bool isAcknowledged = await _waitForControllerResponse(payload, key, i);

      if(mounted){
        setState(() {
          payloadStatuses[i]['status'] = isAcknowledged ? 'Sent' : 'Failed';
        });
      }
    }
    _checkAllProcessed();
  }

  Future<bool> _waitForControllerResponse(String payload, String key, int index) async {
    try {
      Map<String, dynamic> gemPayload = {};
      if (widget.isToGem) {
        gemPayload = {
          "5900": {
            "5901": payload,
          }
        };
      }
      final result = await context.read<CommunicationService>().sendCommand(
        serverMsg: '',
        payload: widget.isToGem ? jsonEncode(gemPayload) : widget.isWlc ? Constants.sendPayloadWithCrc(jsonDecode(payload)[key]) :
        jsonDecode(payload)[key],
      );
      debugPrint("progress dialog result => $result");
      // await widget.mqttService.topicToPublishAndItsMessage(
      //   widget.isToGem ? jsonEncode(gemPayload) : widget.isWlc ? Constants.sendPayloadWithCrc(jsonDecode(payload)[key]) :
      //   jsonDecode(payload)[key],
      //   "${Environment.mqttPublishTopic}/${widget.deviceId}",);

      bool isAcknowledged = false;
      int maxWaitTime = 20;
      int elapsedTime = 0;
      int oroPumpIndex = 0;
      if(widget.isToGem) {
        oroPumpIndex = context.read<PreferenceProvider>().commonPumpSettings!.indexWhere((element) => element.deviceId == payload.split('+')[2]);
      }
      await for (var mqttMessage in widget.mqttService.preferenceAckStream.timeout(
        Duration(seconds: maxWaitTime),
        onTimeout: (sink) {
          sink.close();
        },
      )) {
        if (elapsedTime >= maxWaitTime || breakLoop) break;

        if (mqttMessage!['cM'].contains(key) && (widget.isToGem ? mqttMessage['cC'] == payload.split('+')[2] : true)) {
          context.read<PreferenceProvider>().updateControllerReaStatus(
              key: key,
              oroPumpIndex: oroPumpIndex,
              failed: widget.shouldSendFailedPayloads
          );
          isAcknowledged = true;
          break;
        }

        await Future.delayed(const Duration(seconds: 1));
        elapsedTime++;
      }

      return isAcknowledged;
    } catch (error, stackTrace) {
      print("==================== ERROR IN WAIT FOR RESPONSE ====================");
      print("Error: $error");
      print("StackTrace:\n$stackTrace");
      print("====================================================================");
      return false;
    }
  }

  Future<void> retryFailedPayloads() async {
    setState(() {
      breakLoop = false;
      mqttError = '';
    });

    for (int i = 0; i < payloadStatuses.length; i++) {
      if (payloadStatuses[i]['selected'] && payloadStatuses[i]['status'] == 'Failed') {
        var payload = payloadStatuses[i]['payload'];
        var payloadToDecode = widget.isToGem ? payload.split('+')[4] : payload;
        var decodedData = jsonDecode(payloadToDecode);
        var key = decodedData.keys.first;

        setState(() {
          payloadStatuses[i]['status'] = 'Retrying';
        });

        bool isAcknowledged = await _waitForControllerResponse(payload, key, i);

        setState(() {
          payloadStatuses[i]['status'] = isAcknowledged ? 'Sent' : 'Failed';
        });
      }
    }

    _checkAllProcessed();
  }

  Future<void> handleRetry() async {
    if (!widget.mqttService.isConnected) {
      setState(() {
        mqttError = 'MQTT Disconnected. Reconnecting...';
      });

      await widget.mqttService.connect();
      setState(() {
        mqttError = 'Trying to reconnect...';
      });
      await Future.delayed(const Duration(seconds: 3));
      if (widget.mqttService.isConnected) {
        setState(() {
          mqttError = '';
        });
        retryFailedPayloads();
      } else {
        setState(() {
          mqttError = 'MQTT Reconnection Failed!';
        });
      }
    } else {
      retryFailedPayloads();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Processing Payloads", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 350,
            width: 300,
            child: ListView.builder(
              itemCount: payloadStatuses.length,
              itemBuilder: (context, index) {
                var status = payloadStatuses[index];
                String? key = status['key'];
                print("key : $key");
                String message = statusMessages[key] ?? "Unknown setting";

                return CheckboxListTile(
                  secondary: SizedBox(
                    height: 32,
                    width: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status['status'] == 'Sent'
                                ? Colors.green
                                : (status['status'] == 'Failed' ? Colors.red : Theme.of(context).primaryColor),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        if (status['status'] == 'Sending' || status['status'] == 'Retrying')
                          const SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  title: Text("${status['reference']}"),
                  subtitle: Text(message),
                  value: payloadStatuses[index]['selected'],
                  onChanged: (bool? value) {
                    setState(() {
                      payloadStatuses[index]['selected'] = value!;
                    });
                  },
                );
              },
            ),
          ),
          if (mqttError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                mqttError,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      actions: [
        if(isAllProcessed && isAllSent)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text("Done"),
          )
        else
          FilledButton(
            onPressed: () {
              breakLoop = true;
              Navigator.of(context).pop(false);
            },
            child: const Text("Cancel"),
          ),
        if (isAllProcessed && !isAllSent)
          FilledButton(
            onPressed: handleRetry,
            child: const Text("Retry"),
          ),
        if (!isSending && !isAllProcessed)
          FilledButton(
            onPressed: _processPayloads,
            child: const Text("Send"),
          ),
      ],
    );
  }
}
