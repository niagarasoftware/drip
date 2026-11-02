import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/customer/site_model.dart';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/constants.dart';
import '../../utils/snack_bar.dart';

class NodeListViewModel extends ChangeNotifier {

  final Repository repository;

  late MqttPayloadProvider payloadProvider;

  List<NodeListModel> nodeList;

  List<dynamic> _previousLiveMessage = [];
  List<dynamic> _previousRelayStatus = [];


  NodeListViewModel(BuildContext context, this.repository, this.nodeList) {
    payloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
  }

  bool shouldUpdate(List<String> newLiveMessage, List<String> newRelayStatus) {
    return newLiveMessage.join() != _previousLiveMessage.join() ||
        newRelayStatus.join() != _previousRelayStatus.join();
  }

  void onLivePayloadReceived(List<String> nodeLiveMeg, List<String> inputOutputStatus, bool isOMs) {

    try {
      for (String group in nodeLiveMeg) {
        List<String> values = group.split(",");
        if (isOMs ? values.length < 3 : values.length < 5) continue;

        int? sNo = int.tryParse(values[0]);
        double? sVolt = double.tryParse(values[1]);
        double? batVolt = double.tryParse(values[2]);
        int? status = isOMs ? 0 : int.tryParse(values[3]);
        String lastFeedback = isOMs ? values[3] : values[4];
        String version = values.length > 5 ? values[5] : '0.0.0';
        String missedCommunication = isOMs ? '0': values[6];

        if (sNo == null || sVolt == null || batVolt == null || status == null) continue;

        for (var node in nodeList) {
          if (node.serialNumber == sNo) {
            node.sVolt = sVolt;
            node.batVolt = batVolt;
            node.status = status;
            node.lastFeedbackReceivedTime = lastFeedback;
            node.version = version;
            node.communicationCount = missedCommunication;
            break;
          }
        }
      }

      for (String group in inputOutputStatus) {
        List<String> values = group.split(",");
        if (values.length < 2) continue;

        String relaySNo = values[0];
        int? relayStatus = int.tryParse(values[1]);
        if (relayStatus == null) continue;

        outerLoop:
        for (var node in nodeList) {
          for (var relay in node.rlyStatus) {
            if (relay.sNo.toString() == relaySNo) {
              relay.status = relayStatus;
              break outerLoop;
            }
          }
        }
      }

      nodeList = List.from(nodeList);

      _previousLiveMessage = nodeLiveMeg;
      _previousRelayStatus = inputOutputStatus;

      notifyListeners();

    } catch (e, st) {
      debugPrint("Error parsing payload: $e");
      debugPrint(st as String?);
    }
  }


  double calculateDynamicHeight(NodeListModel node) {
    double baseHeight = 110;
    double additionalHeight = 0;

    if (node.rlyStatus.isNotEmpty) {
      additionalHeight += calculateGridHeight(node.rlyStatus.length);
    }

    return baseHeight + additionalHeight;
  }

  double calculateGridHeight(int itemCount) {
    int rows = (itemCount / 5).ceil();
    return rows * 60;
  }

  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) {
      return "No feedback received";
    }
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm a');
      return formatter.format(dateTime);
    } catch (e) {
      return "00 00, 0000, 00:00";
    }
  }

  String mapInterfaceType(String interface) {
    switch (interface) {
      case "RS485":
        return "Wired";
      case "LoRa":
        return "Wireless";
      case "MQTT":
        return "GSM";
      default:
        return interface;
    }
  }

  Future<void> showEditProductDialog(BuildContext context, String nodeName, int nodeId,
      int index, int customerId, int userId, int controllerId) async {
    final TextEditingController nodeNameController = TextEditingController(text: nodeName);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Node Name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nodeNameController,
              maxLength: 30,
              decoration: const InputDecoration(hintText: "Enter node name"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Node name cannot be empty';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Map<String, Object> body = {"userId": customerId, "controllerId": controllerId,
                    "nodeControllerId": nodeId, "deviceName": nodeNameController.text, "modifyUser": userId};

                  try {
                    var response = await repository.updateUserNodeDetails(body);
                    if (response.statusCode == 200) {
                      final jsonData = jsonDecode(response.body);
                      if (jsonData["code"] == 200) {
                        nodeList[index].deviceName = nodeNameController.text;
                        notifyListeners();
                        GlobalSnackBar.show(context, 'Node name updated successfully', 200);
                        Navigator.of(context).pop();
                      }
                    }
                  } catch (error) {
                    debugPrint('Error fetching category list: $error');
                  }

                }
              },
            ),
          ],
        );
      },
    );
  }


  void setSerialToAllNodes(deviceId, int customerId, int controllerId, int userId){
    Future.delayed(const Duration(milliseconds: 1000), () {
      String payLoadFinal = jsonEncode({
        "2300": {"2301": ""}
      });
      MqttService().topicToPublishAndItsMessage(payLoadFinal, '${AppConstants.publishTopic}/$deviceId');
      sentToServer('Set serial for all nodes comment sent successfully', payLoadFinal, customerId, controllerId, userId );
    });
  }

  void testCommunication(deviceId, int customerId, int controllerId, int userId){
    Future.delayed(const Duration(milliseconds: 1000), () {
      String payLoadFinal = jsonEncode({
        "4500": {"4501": ""}
      });
      MqttService().topicToPublishAndItsMessage(payLoadFinal, '${AppConstants.publishTopic}/$deviceId');
      sentToServer('Test Communication comment sent successfully', payLoadFinal, customerId, controllerId, userId);
    });
  }

  void actionSerialSet(int index, deviceId, int customerId, int controllerId, int userId){
    Future.delayed(const Duration(milliseconds: 1000), () {
      String payLoadFinal = jsonEncode({
        "2300": {"2301": "${nodeList[index].serialNumber}"}
      });
      MqttService().topicToPublishAndItsMessage(payLoadFinal, '${AppConstants.publishTopic}/$deviceId');
      sentToServer('Serial set for the ${nodeList[index].deviceName} all Relay', payLoadFinal, customerId, controllerId, userId);
    });
  }

  void sentToServer(String msg, String data, int customerId, int controllerId, int userId) async
  {
    Map<String, Object> body = {"userId": customerId, "controllerId": controllerId, "messageStatus": msg, "hardware": jsonDecode(data), "createUser": userId};
    final response = await Repository(HttpService()).sendManualOperationToServer(body);
    if (response.statusCode == 200) {
      debugPrint(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

}