import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/program_library.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/schedule_screen.dart';
import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../Constants/properties.dart';
import '../../../services/mqtt_service.dart';
import '../../../utils/constants.dart';
import '../repository/irrigation_program_repo.dart';
import '../state_management/irrigation_program_provider.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../StateManagement/overall_use.dart';
import '../widgets/custom_alert_dialog.dart';
import '../widgets/custom_native_time_picker.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../../../services/http_service.dart';
import '../widgets/custom_sliding_button.dart';
import '../widgets/progress_dialog_ecogem.dart';
import 'conditions_screen.dart';

class AdditionalDataScreen extends StatefulWidget {
  final int serialNumber;
  final bool isIrrigationProgram;
  final int userId;
  final int customerId;
  final int controllerId;
  final String deviceId;
  final bool toDashboard;
  final String? programType;
  final bool fromDealer;
  final int groupId, categoryId;
  final int modelId;
  final String deviceName;
  final String categoryName;
  const AdditionalDataScreen({super.key, required this.serialNumber,
    required this.isIrrigationProgram, required this.userId, required this.controllerId,
    required this.deviceId, required this.toDashboard, this.programType,
    required this.fromDealer, required this.customerId, required this.groupId, required this.categoryId,
    required this.modelId,
    required this.deviceName,
    required this.categoryName,});

  @override
  State<AdditionalDataScreen> createState() => _AdditionalDataScreenState();
}

class _AdditionalDataScreenState extends State<AdditionalDataScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  String tempProgramName = '';
  late OverAllUse overAllPvd;
  late MqttPayloadProvider mqttPayloadProvider;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    mqttPayloadProvider =  Provider.of<MqttPayloadProvider>(context, listen: false);
  }
  @override
  Widget build(BuildContext context) {
    final doneProvider = Provider.of<IrrigationProgramMainProvider>(context);
    mqttPayloadProvider =  Provider.of<MqttPayloadProvider>(context);
    overAllPvd = Provider.of<OverAllUse>(context,listen: false);
    String programName = doneProvider.programName == ''? "Program ${doneProvider.programCount}" : doneProvider.programName;
    final isEcoGem = [3].contains(widget.modelId);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: [
              const SizedBox(height: 20,),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05, vertical: MediaQuery.of(context).size.width * 0.025),
                  child: ListView(
                    children: [
                      for(var index = 0; index < ((widget.isIrrigationProgram && !isEcoGem) ? 14 : 3); index++)
                        Column(
                          children: [
                            buildListTile(
                              padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width > 1200 ? 8 : 0),
                              context: context,
                              title: isEcoGem ? ['Program Name', 'Valve Off Delay', 'Scale factor'][index].toUpperCase()
                                  : ['Program Name', 'Priority', 'Valve Off Delay', 'Scale factor', 'Cyclic OnTime', 'Cyclic OffTime', 'Enable Pressure', 'Pressure Value', 'Control Mode', 'Set Pressure', 'Pressure Tolerance', 'Set Flow', 'Flow Tolerance', 'Flow Scan Time'][index].toUpperCase(),
                              subTitle: isEcoGem ? [tempProgramName != '' ? tempProgramName : widget.serialNumber == 0
                                  ? "Program ${doneProvider.programCount}"
                                  : doneProvider.programDetails!.programName.isNotEmpty ? programName : doneProvider.programDetails!.defaultProgramName,
                                'Set valve off delay', 'Adjust duration or flow'][index]
                                  : [tempProgramName != '' ? tempProgramName : widget.serialNumber == 0
                                  ? "Program ${doneProvider.programCount}"
                                  : doneProvider.programDetails!.programName.isNotEmpty ? programName : doneProvider.programDetails!.defaultProgramName,
                                'Prioritize the program to run', 'Set valve off delay', 'Adjust duration or flow', 'Set Cyclic On Time', 'Set Cyclic Off Time', 'Enable Pressure', 'Set Pressure Value', 'Choose control mode', 'Set Pressure Value', 'Set Pressure Tolerance', 'Set Flow Value', 'Set Flow Tolerance', 'Set Scan Time'][index],
                              textColor: Colors.black,
                              icon: isEcoGem
                                  ? [Icons.drive_file_rename_outline_rounded, Icons.timer_outlined, Icons.safety_check][index]
                                  : [Icons.drive_file_rename_outline_rounded, Icons.priority_high, Icons.timer_outlined, Icons.safety_check, Icons.timer, Icons.timer, Icons.check_box, Icons.speed, Icons.speed, Icons.speed, Icons.speed, Icons.speed, Icons.speed, Icons.timelapse][index],
                              trailing: isEcoGem ? [
                                InkWell(
                                  child: Icon(Icons.drive_file_rename_outline_rounded, color: Theme.of(context).primaryColor,),
                                  onTap: () {
                                    _textEditingController.text = widget.serialNumber == 0
                                        ? "Program ${doneProvider.programCount}"
                                        : doneProvider.programDetails!.programName.isNotEmpty ? programName : doneProvider.programDetails!.defaultProgramName;
                                    _textEditingController.selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: _textEditingController.text.length,
                                    );
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Edit program name"),
                                        content: Form(
                                          key: _formKey,
                                          child: TextFormField(
                                            autofocus: true,
                                            controller: _textEditingController,
                                            // onChanged: (newValue) => tempProgramName = newValue,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(20),
                                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.]'))
                                            ],
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return "Name cannot be empty";
                                              } else if (doneProvider.programLibrary!.program.any((element) => element.programName == value)) {
                                                return "Name already exists";
                                              } else {
                                                setState(() {
                                                  tempProgramName = value;
                                                });
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(),
                                            child: const Text("CANCEL", style: TextStyle(color: Colors.red),),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (_formKey.currentState!.validate()) {
                                                doneProvider.updateProgramName(tempProgramName, 'programName');
                                                Navigator.of(ctx).pop();
                                              }
                                            },
                                            child: const Text("OKAY", style: TextStyle(color: Colors.green),),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                CustomNativeTimePicker(
                                  initialValue: doneProvider.delayBetweenZones != "" ? doneProvider.delayBetweenZones : "00:00:00",
                                  is24HourMode: false,
                                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                  onChanged: (newTime){
                                    doneProvider.updateProgramName(newTime, 'delayBetweenZones');
                                  }, modelId: widget.modelId,
                                ),
                                IntrinsicWidth(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue: doneProvider.adjustPercentage != "" ? doneProvider.adjustPercentage : "100",
                                          decoration: const InputDecoration(
                                            hintText: '0%',
                                          ),
                                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.deny(RegExp('[^0-9]')),
                                            LengthLimitingTextInputFormatter(5),
                                          ],
                                          onChanged: (newValue){
                                            doneProvider.updateProgramName(newValue, 'adjustPercentage');
                                          },
                                        ),
                                      ),
                                      Text("%", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),)
                                    ],
                                  ),
                                )
                              ][index]
                                  : [
                                InkWell(
                                  child: Icon(Icons.drive_file_rename_outline_rounded, color: Theme.of(context).primaryColor,),
                                  onTap: () {
                                    _textEditingController.text = widget.serialNumber == 0
                                        ? "Program ${doneProvider.programCount}"
                                        : doneProvider.programDetails!.programName.isNotEmpty ? programName : doneProvider.programDetails!.defaultProgramName;
                                    _textEditingController.selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: _textEditingController.text.length,
                                    );

                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Edit program name"),
                                        content: Form(
                                          key: _formKey,
                                          child: TextFormField(
                                            autofocus: true,
                                            controller: _textEditingController,
                                            // onChanged: (newValue) => tempProgramName = newValue,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(20),
                                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.]'))
                                            ],
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return "Name cannot be empty";
                                              } else if (doneProvider.programLibrary!.program.any((element) => element.programName == value)) {
                                                return "Name already exists";
                                              } else {
                                                setState(() {
                                                  tempProgramName = value;
                                                });
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(),
                                            child: const Text("CANCEL", style: TextStyle(color: Colors.red),),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (_formKey.currentState!.validate()) {
                                                doneProvider.updateProgramName(tempProgramName, 'programName');
                                                Navigator.of(ctx).pop();
                                              }
                                            },
                                            child: const Text("OKAY", style: TextStyle(color: Colors.green),),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                buildPopUpMenuButton(
                                    context: context,
                                    dataList: doneProvider.priorityList.map((item) => item).toList(),
                                    onSelected: (newValue) => doneProvider.updateProgramName(newValue, 'priority'),
                                    selected: doneProvider.priority,
                                    child: Text(doneProvider.priority, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),)
                                ),
                                CustomNativeTimePicker(
                                  initialValue: Constants.showHourAndMinuteOnly(doneProvider.delayBetweenZones != ""
                                      ? doneProvider.delayBetweenZones.length > 5
                                      ? doneProvider.delayBetweenZones
                                      : '${doneProvider.delayBetweenZones}:00'
                                      : "00:00:00", widget.modelId),
                                  is24HourMode: false,
                                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                  onChanged: (newTime){
                                    doneProvider.updateProgramName(newTime, 'delayBetweenZones');
                                  },
                                  modelId: widget.modelId,
                                ),
                                IntrinsicWidth(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue: doneProvider.adjustPercentage != "" ? doneProvider.adjustPercentage : "100",
                                          decoration: const InputDecoration(
                                            hintText: '0%',
                                          ),
                                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.deny(RegExp('[^0-9]')),
                                            LengthLimitingTextInputFormatter(5),
                                          ],
                                          onChanged: (newValue){
                                            doneProvider.updateProgramName(newValue, 'adjustPercentage');
                                          },
                                        ),
                                      ),
                                      Text("%", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),)
                                    ],
                                  ),
                                ),
                                CustomNativeTimePicker(
                                  initialValue: Constants.showHourAndMinuteOnly(doneProvider.cyclicOnTime, widget.modelId),
                                  is24HourMode: false,
                                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                  onChanged: (newTime){
                                    doneProvider.updateProgramName(newTime, 'cyclicOnTime');
                                  },
                                  modelId: widget.modelId,
                                ),
                                CustomNativeTimePicker(
                                  initialValue: Constants.showHourAndMinuteOnly(doneProvider.cyclicOffTime, widget.modelId),
                                  is24HourMode: false,
                                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                  onChanged: (newTime){
                                    doneProvider.updateProgramName(newTime, 'cyclicOffTime');
                                  },
                                  modelId: widget.modelId,
                                ),
                                Checkbox(
                                    value: doneProvider.enablePressure,
                                    onChanged: (newValue){
                                      doneProvider.updateProgramName(newValue, 'enablePressure');
                                    }
                                ),
                                IntrinsicWidth(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue: doneProvider.pressureValue,
                                          decoration: const InputDecoration(
                                            // hintText: '0%',
                                          ),
                                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: AppProperties.regexForDecimal,
                                          onChanged: (newValue){
                                            doneProvider.updateProgramName(newValue, 'pressureValue');
                                          },
                                        ),
                                      ),
                                      Text("bar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),)
                                    ],
                                  ),
                                ),
                                IntrinsicWidth(
                                  child: DropdownButton<String>(
                                    value: doneProvider.controlMode, // define a state variable like String? selectedValue;
                                    items: <String>['pressure', 'flow']
                                        .map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      doneProvider.updateProgramName(newValue, 'controlMode');

                                    },
                                  ),
                                ),
                                IntrinsicWidth(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue: doneProvider.setPressure,
                                          decoration: const InputDecoration(
                                            // hintText: '0%',
                                          ),
                                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: AppProperties.regexForDecimal,
                                          onChanged: (newValue){
                                            doneProvider.updateProgramName(newValue, 'setPressure');
                                          },
                                        ),
                                      ),
                                      Text("bar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),)
                                    ],
                                  ),
                                ),
                                IntrinsicWidth(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue: doneProvider.pressureTolerance,
                                          decoration: const InputDecoration(
                                            // hintText: '0%',
                                          ),
                                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: AppProperties.regexForDecimal,
                                          onChanged: (newValue){
                                            doneProvider.updateProgramName(newValue, 'pressureTolerance');
                                          },
                                        ),
                                      ),
                                      Text("%", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),)
                                    ],
                                  ),
                                ),
                                IntrinsicWidth(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue: doneProvider.setFlow,
                                          decoration: const InputDecoration(
                                            // hintText: '0%',
                                          ),
                                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: AppProperties.regexForDecimal,
                                          onChanged: (newValue){
                                            doneProvider.updateProgramName(newValue, 'setFlow');
                                          },
                                        ),
                                      ),
                                      Text("l/h", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),)
                                    ],
                                  ),
                                ),
                                IntrinsicWidth(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue: doneProvider.flowTolerance,
                                          decoration: const InputDecoration(
                                            // hintText: '0%',
                                          ),
                                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: AppProperties.regexForDecimal,
                                          onChanged: (newValue){
                                            doneProvider.updateProgramName(newValue, 'flowTolerance');
                                          },
                                        ),
                                      ),
                                      Text("%", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),)
                                    ],
                                  ),
                                ),
                                CustomNativeTimePicker(
                                  initialValue: Constants.showHourAndMinuteOnly(doneProvider.flowScanTime, widget.modelId),
                                  is24HourMode: false,
                                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize),
                                  onChanged: (newTime){
                                    doneProvider.updateProgramName(newTime, 'flowScanTime');
                                  },
                                  modelId: widget.modelId,
                                ),
                              ][index],
                            ),
                            const SizedBox(height: 45,)
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if(!(widget.isIrrigationProgram))
                SlidingSendButton(
                  onSend: (){
                    sendFunction();
                  },
                ),
              if(!(widget.isIrrigationProgram))
                const SizedBox(height: 100,)
            ],
          );
        }
    );
  }

  void sendFunction() async{
    final mainProvider = Provider.of<IrrigationProgramMainProvider>(context, listen: false);
    Map<String, dynamic> dataToMqtt = mainProvider.dataToMqtt(widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber, widget.programType);
    Map<String, dynamic> dataToMqttEcoGem = mainProvider.dataToMqttForEcoGem(widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber, widget.programType);
    dynamic ecoGemWFPayload;
    if(AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) {
      ecoGemWFPayload = mainProvider.ecoGemPayloadForWF(widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber);
    }
    List<String> ecoGemWFPayloadList = [];
    ecoGemWFPayloadList.add(jsonEncode(dataToMqttEcoGem));
    if(AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) {
      for(int i = 0; i < ecoGemWFPayload.length; i++) {
        final payload = {
          "260${i + 1}": {
            "2501": ecoGemWFPayload[i]
          }
        };
        ecoGemWFPayloadList.add(jsonEncode(payload));
      }
    }
    Map<String, dynamic> userData = {
      "defaultProgramName": mainProvider.defaultProgramName,
      "userId": widget.customerId,
      "controllerId": widget.controllerId,
      "createUser": widget.userId,
      "serialNumber": widget.serialNumber == 0 ? mainProvider.serialNumberCreation : widget.serialNumber,
    };
    if(mainProvider.irrigationLine!.sequence.isNotEmpty) {
      // print(mainProvider.selectionModel.data!.toJson());
      // print(mainProvider.additionalData!.toJson());
      var dataToSend = {
        "sequence": mainProvider.irrigationLine!.sequence,
        "schedule": mainProvider.sampleScheduleModel!.toJson(),
        "conditions": mainProvider.sampleConditions != null
            ? mainProvider.sampleConditions!.toJson()
            : [],
        "waterAndFert": mainProvider.sequenceData,
        "selection": {
          ...mainProvider.additionalData!.toJson(),
          "selected": mainProvider.selectedObjects!.map((e) => e.toJson()).toList(),
        },
        "alarm": mainProvider.newAlarmList!.toJson(),
        "programName": mainProvider.programName,
        "priority": mainProvider.priority,
        "delayBetweenZones": mainProvider.programDetails!.delayBetweenZones,
        "adjustPercentage": mainProvider.programDetails!.adjustPercentage,
        "cyclicOnTime": "00:00:00",
        "cyclicOffTime": "00:00:00",
        "isPressureEnabled": '0',
        "pressure": "",
        "incompleteRestart": mainProvider.isCompletionEnabled ? "1" : "0",
        "controllerReadStatus": '0',
        "programType": mainProvider.selectedProgramType,
        "hardware": AppConstants.ecoGemAndPlusModelList.contains(widget.modelId) ? ecoGemWFPayloadList : dataToMqtt
      };
      userData.addAll(dataToSend);
      try {
        if(AppConstants.ecoGemAndPlusModelList.contains(widget.modelId)) {
          final result = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return EcoGemProgressDialog(
                payloads: ecoGemWFPayloadList,
                deviceId: widget.deviceId,
                mqttService: MqttService(),
              );
            },
          );

          if (result != null) {
            setState(() {
              userData['controllerReadStatus'] = result;
            });
          }
        } else {
          await validatePayloadSent(
              dialogContext: context,
              context: context,
              mqttPayloadProvider: mqttPayloadProvider,
              acknowledgedFunction: () {
                setState(() {
                  userData['controllerReadStatus'] = "1";
                });
                // showSnackBar(message: "${mqttPayloadProvider.messageFromHw['Name']} from controller", context: context);
              },
              payload: dataToMqtt,
              payloadCode: "2500",
              deviceId: widget.deviceId
          );
        }
      } catch(error) {
        ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: 'Failed to update because of $error'));
        // print("Error: $error");
      }

      Future.delayed(const Duration(milliseconds: 300), () async {
        final IrrigationProgramRepository repository = IrrigationProgramRepository(HttpService());
        final createUserProgram = await repository.createUserProgram(userData);
        final response = jsonDecode(createUserProgram.body);
        if(createUserProgram.statusCode == 200) {
          await mainProvider.programLibraryData(widget.customerId, widget.controllerId);
          ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: response['message']));
          Navigator.of(context).pop();
        }
      });
    }
    else {
      showAdaptiveDialog<Future>(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: 'Warning',
            content: "Select valves to be sequence for Irrigation Program",
            actions: [
              TextButton(child: const Text("OK"), onPressed: () => Navigator.of(context).pop(),),
            ],
          );
        },
      );
    }
  }
}