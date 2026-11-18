import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../StateManagement/mqtt_payload_provider.dart';
import '../../models/PumpConditionModel.dart';
import '../../modules/IrrigationProgram/view/program_library.dart';
import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/constants.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';
import '../../utils/snack_bar.dart';

class PumpConditionScreen extends StatefulWidget {
  final dynamic userId;
  final dynamic customerId;
  final dynamic controllerId;
  final dynamic modelid;
  final String imeiNo;
  final bool? isProgram;

  const PumpConditionScreen({
    Key? key,
    required this.userId,
    required this.controllerId,
    required this.modelid,
    required this.imeiNo,
    this.isProgram, this.customerId,
  }) : super(key: key);

  @override
  State<PumpConditionScreen> createState() => _PumpConditionScreenState();
}

class _PumpConditionScreenState extends State<PumpConditionScreen> {
  late PumpConditionModel pumpConditionModel = PumpConditionModel();
  late MqttPayloadProvider mqttPayloadProvider;
  String selectedMode = "";
  bool isNova = false;

  @override
  void initState() {
     isNova = [...AppConstants.ecoGemModelList].contains(widget.modelid);

    super.initState();
    mqttPayloadProvider =
        Provider.of<MqttPayloadProvider>(context, listen: false);
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final repository = Repository(HttpService());
      var getUserDetails = await repository.getUserPlanningPumpCondition({
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
      });

      if (getUserDetails.statusCode == 200) {
        setState(() {
          var jsonData = jsonDecode(getUserDetails.body);
          pumpConditionModel = PumpConditionModel.fromJson(jsonData);
          selectedMode = pumpConditionModel.data?.novaselectmode ?? "Alternative";
        });
      }
    } catch (e, stackTrace) {
      AppLog.log('Error in fetchData: $e');
      AppLog.log('Stack trace: $stackTrace');
    }
  }

  void togglePumpSelection(PumpCondition currentPump, PumpCondition targetPump) {
    var selectedList = currentPump.selectedPumps ?? [];

    final alreadySelected =
    selectedList.any((p) => p.sNo == targetPump.sNo);

    setState(() {
      if (alreadySelected) {
        selectedList.removeWhere((p) => p.sNo == targetPump.sNo);
      } else {
        selectedList.add(SelectedPump(
          sNo: targetPump.sNo,
          objectId: targetPump.objectId,
        ));
      }

      currentPump.selectedPumps = selectedList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allPumps = pumpConditionModel.data?.pumpCondition ?? [];
     return Scaffold(
      backgroundColor: const Color(0xffE6EDF5),
      appBar: MediaQuery.of(context).size.width <= 500 ? AppBar(
        title: const Text('Pump Conditions'),
      ) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: isNova ?  Card(
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Nova Pump Condition',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8.0),
              Container(height: 0.5, color: Colors.grey),
              const SizedBox(height: 8.0),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Pump Mode",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  /// --- TWO CHIPS WITH NEW NAMES ---
                  Wrap(
                    spacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text("Alternative Pump"),
                        selected: selectedMode == "Alternative",
                        selectedColor: Colors.greenAccent.shade100,
                        onSelected: (_) {
                          setState(() {
                            selectedMode = "Alternative";
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text("Combined Pumps"),
                        selected: selectedMode == "combined",
                        selectedColor: Colors.greenAccent.shade100,
                        onSelected: (_) {
                          setState(() {
                            selectedMode = "combined";
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Result Text
                  Text(
                    "Selected Mode: ${selectedMode.isEmpty ? 'None' : selectedMode}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )

          ],
          ),
        ),
      )  : Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: allPumps.map((pumpCondition) {
            var selectedPumps = pumpCondition.selectedPumps ?? [];

            return Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        pumpCondition.name ?? 'No Name',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: allPumps
                          .where((pump) => pump.sNo != pumpCondition.sNo)
                          .map((pump) {
                        bool isSelected = selectedPumps.any(
                                (sp) => sp.sNo == pump.sNo);

                        return GestureDetector(
                          onTap: () => togglePumpSelection(pumpCondition, pump),
                          child: Chip(
                            label: Text(pump.name ?? 'Unknown Pump'),
                            backgroundColor: isSelected
                                ? Colors.yellowAccent.shade100
                                : Colors.grey.shade300,
                            avatar: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                                : const Icon(Icons.circle_outlined, color: Colors.grey, size: 18),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        onPressed: _sendData,
        child: const Icon(Icons.send),
        tooltip: 'Send Data',
      ),
    );
  }

  String convertPumpDataToString(PumpConditionModel model) {
    final buffer = StringBuffer();
    final pumps = model.data?.pumpCondition ?? [];

    for (var pump in pumps) {
      buffer.write(pump.sNo?.toString() ?? '');
      final selected = pump.selectedPumps ?? [];

      if (selected.isNotEmpty) {
        buffer.write(',');
        buffer.writeAll(
          selected.map((sp) => sp.sNo?.toString() ?? ','),
          '_',
        );
      }
      else
        {
          buffer.write(',');
        }

      buffer.write(';');
    }

    return buffer.toString();
  }


  Future<void> _sendData() async {
     final repository = Repository(HttpService());

    String mqttSendData = convertPumpDataToString(pumpConditionModel);
    AppLog.log('mqttSendData$mqttSendData');

    // Prepare JSON for server
    Map<String, dynamic> pumpConditionJson = pumpConditionModel.toJson();
    Map<String, dynamic> pumpConditionServerData = {
      "pumpCondition": pumpConditionJson["data"]?["pumpCondition"] ?? [],
      "controllerReadStatus": "0",
      "novaMode": selectedMode,
    };
     var novadata = selectedMode == "Alternative" ? "1" : "0";
    // MQTT Payload format
    Map<String, dynamic> payLoadFinal = {
      "7100":
        {"7101": isNova ? novadata : mqttSendData},
    };

    AppLog.log("payLoadFinal,$payLoadFinal");
    // Main request body
    Map<String, dynamic> body = {
      "userId": widget.customerId,
      "controllerId": widget.controllerId,
      "pumpCondition": pumpConditionServerData,
      "hardware": payLoadFinal,
      "createUser": widget.userId,
    };


    try {
      final getUserDetails = await repository.updateUserPlanningPumpCondition(body);
      final jsonDataResponse = jsonDecode(getUserDetails.body);

      AppLog.log('Response ---> $jsonDataResponse');

      if (MqttService().isConnected == true) {
        await validatePayloadSent(
          dialogContext: context,
          context: context,
          mqttPayloadProvider: mqttPayloadProvider,
          acknowledgedFunction: () async {
            setState(() {
              body["pumpCondition"]["controllerReadStatus"] = "1";
            });
          },
          payload: payLoadFinal,
          payloadCode: '7100',
          deviceId: widget.imeiNo,
        );
      } else {
        GlobalSnackBar.show(context, 'MQTT is Disconnected', 201);
      }

      GlobalSnackBar.show(
        context,
        jsonDataResponse['message'],
        jsonDataResponse['code'],
      );
    } catch (e ,stacktrace) {
      AppLog.log("Error in _sendData: $e");
      AppLog.log("stacktrace in _sendData: $stacktrace");
      GlobalSnackBar.show(context, 'Error sending data: $e', 500);
    }
  }

}
