import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../../../services/mqtt_service.dart';
import '../../../utils/environment.dart';

class EcoGemProgressDialog extends StatefulWidget {
  final List<String> payloads;
  final String deviceId;
  final MqttService mqttService;

  const EcoGemProgressDialog({
    super.key,
    required this.payloads,
    required this.deviceId,
    required this.mqttService,
  });

  @override
  State<EcoGemProgressDialog> createState() => _EcoGemProgressDialogState();
}

class _EcoGemProgressDialogState extends State<EcoGemProgressDialog> {
  late List<Map<String, dynamic>> payloadStatuses;
  bool breakLoop = false;
  bool isAllProcessed = false;
  bool isAllSent = false;
  String mqttError = '';
  bool isSending = false;
  String controllerReadStatus = '0';

  static const Map<String, String> statusMessages = {
    "2500": "Program Payload",
    "2601": "1 to 8 zones payload",
    "2602": "9 to 16 zones payload",
    "2603": "17 to 24 zones payload",
    "2604": "25 to 32 zones payload",
    "7000": "Day count RTC payload",
    "8000": "Program queue payload",
  };

  @override
  void initState() {
    super.initState();
    if (mounted) {
      payloadStatuses = widget.payloads.map((payload) {
        // Decode JSON string to extract PayloadCode
        Map<String, dynamic> decodedPayload = jsonDecode(payload);
        String key = decodedPayload.keys.first;
        return {
          'payload': payload,
          'key': key,
          'status': 'Pending',
          'selected': true,
          'reference': statusMessages[key] ?? 'Unknown setting',
        };
      }).toList();
    }
  }

  void _checkAllProcessed() {
    bool allProcessed = payloadStatuses.where((e) => e['selected']).every((p) => p['status'] != 'Pending');
    bool allSent = payloadStatuses.where((e) => e['selected']).every((p) => p['status'] == 'Sent');

    if(mounted) {
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

    for (int i = 0; i < payloadStatuses.length && !breakLoop; i++) {
      if (!payloadStatuses[i]['selected']) continue;

      var payload = payloadStatuses[i]['payload'];
      var key = payloadStatuses[i]['key'];

      setState(() {
        payloadStatuses[i]['status'] = 'Sending';
      });

      await Future.delayed(const Duration(seconds: 2));
      bool isAcknowledged = await _waitForControllerResponse(payload, i, key);

      if (mounted) {
        setState(() {
          payloadStatuses[i]['status'] = isAcknowledged ? 'Sent' : 'Failed';
        });
      }

      // Wait briefly before sending the next payload
      if (isAcknowledged && !breakLoop) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _checkAllProcessed();
  }

  Future<bool> _waitForControllerResponse(String payload, int index, String key) async {
    try {
      controllerReadStatus = '0';
      await widget.mqttService.topicToPublishAndItsMessage(
        payload,
        "${Environment.mqttPublishTopic}/${widget.deviceId}",
      );

      bool isAcknowledged = false;
      const int maxWaitTime = 30;
      int elapsedTime = 0;

      await for (var mqttMessage in widget.mqttService.payloadController.timeout(
        const Duration(seconds: maxWaitTime),
        onTimeout: (sink) => sink.close(),
      )) {
        if (elapsedTime >= maxWaitTime || breakLoop) break;

        if (mqttMessage != null &&
            mqttMessage['cM']['4201']['PayloadCode'] == key &&
            mqttMessage['cC'] == widget.deviceId) {
          isAcknowledged = true;
          controllerReadStatus = '1';
          break;
        }

        await Future.delayed(const Duration(seconds: 1));
        elapsedTime++;
      }

      return isAcknowledged;
    } catch (error) {
      // print('Error in _waitForControllerResponse: $error');
      return false;
    }
  }

  Future<void> retryFailedPayloads() async {
    setState(() {
      breakLoop = false;
      mqttError = '';
    });

    for (int i = 0; i < payloadStatuses.length && !breakLoop; i++) {
      if (payloadStatuses[i]['selected'] && payloadStatuses[i]['status'] == 'Failed') {
        var payload = payloadStatuses[i]['payload'];
        var key = payloadStatuses[i]['key'];

        setState(() {
          payloadStatuses[i]['status'] = 'Retrying';
        });

        bool isAcknowledged = await _waitForControllerResponse(payload, i, key);

        if (mounted) {
          setState(() {
            payloadStatuses[i]['status'] = isAcknowledged ? 'Sent' : 'Failed';
          });
        }
      }
    }

    _checkAllProcessed();
  }

  Future<void> handleRetry() async {
    if (!widget.mqttService.isConnected) {
      setState(() {
        mqttError = 'MQTT Disconnected. Reconnecting...';
      });

      await widget.mqttService.connect().then((_) {
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
      });
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
                  title: Text(message),
                  // subtitle: Text(message),
                  value: status['selected'],
                  onChanged: (bool? value) {
                    if(payloadStatuses.length > 1) {
                      setState(() {
                        payloadStatuses[index]['selected'] = value!;
                      });
                    }
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
        if (isAllProcessed && isAllSent)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(controllerReadStatus);
            },
            child: const Text("Done"),
          )
        else
          FilledButton(
            onPressed: () {
              breakLoop = true;
              Navigator.of(context).pop(controllerReadStatus);
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