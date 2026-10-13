import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/modules/constant/state_management/constant_provider.dart';
import 'package:oro_drip_irrigation/modules/constant/widget/find_suitable_widget.dart';
import 'package:provider/provider.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import '../../../StateManagement/overall_use.dart';
import '../../../Widgets/custom_buttons.dart';
import '../../../Widgets/status_box.dart';
import '../../../services/communication_service.dart';
import '../../../services/mqtt_service.dart';
import '../../../utils/constants.dart';
import '../../IrrigationProgram/widgets/custom_sliding_button.dart';
import '../../config_maker/view/config_web_view.dart';
import '../repository/constant_repository.dart';

class GlobalAlarmInConstant extends StatefulWidget {
  final ConstantProvider constPvd;
  final OverAllUse overAllPvd;
  final Map<String, dynamic> userData;
  const GlobalAlarmInConstant({super.key, required this.constPvd, required this.overAllPvd, required this.userData});

  @override
  State<GlobalAlarmInConstant> createState() => _GlobalAlarmInConstantState();
}

class _GlobalAlarmInConstantState extends State<GlobalAlarmInConstant> {
  ValueNotifier<int> hoveredSno = ValueNotifier<int>(0);
  HardwareAcknowledgementState payloadState = HardwareAcknowledgementState.notSent;
  MqttService mqttService = MqttService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    mqttService.initializeMQTTClient(state: null);
    mqttService.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          spacing: 20,
          children: [
            ResponsiveGridList(
              horizontalGridMargin: 0,
              verticalGridSpacing: 20,
              horizontalGridSpacing: 30,
              verticalGridMargin: 20,
              minItemWidth: 300,
              shrinkWrap: true,
              listViewBuilderOptions: ListViewBuilderOptions(
                physics: const NeverScrollableScrollPhysics(),
              ),
              children: widget.constPvd.globalAlarm
                  .where((defaultSetting) => AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']) ? defaultSetting.gemDisplay : defaultSetting.ecoGemDisplay)
                  .map((globalSetting){
                return AnimatedBuilder(
                    animation: hoveredSno,
                    builder: (context, child){
                      return MouseRegion(
                        onEnter: (_){
                          hoveredSno.value = globalSetting.sNo;
                        },
                        onExit: (_){
                          hoveredSno.value = 0;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                    color: hoveredSno.value == globalSetting.sNo
                                        ? Theme.of(context).primaryColorLight.withOpacity(0.8)
                                        : const Color(0xff000040).withOpacity(0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 4)
                                )
                              ]
                          ),
                          child: ListTile(
                            title: Text(globalSetting.title, style: Theme.of(context).textTheme.labelLarge,),
                            trailing: SizedBox(
                              width: 80,
                              child: FindSuitableWidget(
                                constantSettingModel: globalSetting,
                                onUpdate: (value){
                                  setState(() {
                                    globalSetting.value.value = value;
                                  });
                                },
                                onOk: (){
                                  setState(() {
                                    globalSetting.value.value = widget.overAllPvd.getTime();
                                  });
                                  Navigator.pop(context);
                                },
                                popUpItemModelList: [],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                );
              }).toList(),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              onPressed: (){
                setState(() {
                  payloadState = HardwareAcknowledgementState.notSent;
                  mqttService.acknowledgementPayload = null;
                });
                showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context){
                      return StatefulBuilder(
                          builder: (context, stateSetter){
                            return AlertDialog(
                              title: Text('Send Payload', style: Theme.of(context).textTheme.labelLarge,),
                              content: getHardwareAcknowledgementWidget(payloadState),
                              actions: [
                                if(payloadState != HardwareAcknowledgementState.sending && payloadState != HardwareAcknowledgementState.notSent)
                                  CustomMaterialButton(),
                                if(payloadState == HardwareAcknowledgementState.notSent)
                                  CustomMaterialButton(title: 'Cancel',outlined: true,),
                                if(payloadState == HardwareAcknowledgementState.notSent)
                                  CustomMaterialButton(
                                    onPressed: ()async{
                                      sendToHttp();
                                      var payload = jsonEncode(getConstantHardwarePayload());
                                      int delayDuration = 50;
                                      for(var delay = 0; delay < delayDuration; delay++){
                                        if(delay == 0){
                                          stateSetter((){
                                            setState((){
                                              context.read<CommunicationService>().sendCommand(
                                                serverMsg: '',
                                                payload: payload,
                                              );
                                              payloadState = HardwareAcknowledgementState.sending;
                                            });
                                          });
                                        }
                                        stateSetter((){
                                          setState((){
                                            if(mqttService.acknowledgementPayload != null){
                                              if(validatePayloadFromHardware(mqttService.acknowledgementPayload, ['cC'], widget.userData['deviceId']) && validatePayloadFromHardware(mqttService.acknowledgementPayload!, ['cM', '4201', 'PayloadCode'], '300')){
                                                if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '200'){
                                                  payloadState = HardwareAcknowledgementState.success;
                                                }else if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '90'){
                                                  payloadState = HardwareAcknowledgementState.programRunning;
                                                }else if(mqttService.acknowledgementPayload!['cM']['4201']['Code'] == '1'){
                                                  payloadState = HardwareAcknowledgementState.hardwareUnknownError;
                                                }else{
                                                  payloadState = HardwareAcknowledgementState.errorOnPayload;
                                                }
                                                mqttService.acknowledgementPayload = null;
                                              }
                                            }
                                          });
                                        });
                                        await Future.delayed(const Duration(seconds: 1));
                                        if(delay == delayDuration-1){
                                          stateSetter((){
                                            setState((){
                                              payloadState = HardwareAcknowledgementState.failed;
                                            });
                                          });
                                        }
                                        if(payloadState != HardwareAcknowledgementState.sending){
                                          break;
                                        }
                                      }
                                    },
                                    title: 'Send',
                                  ),
                              ],
                            );
                          }
                      );
                    }
                );
              },
              label: const Text('Click to send constant'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> getConstantHardwarePayload(){
    var generalPayload = widget.constPvd.getGeneralPayload();
    var globalAlarmPayload = widget.constPvd.getGlobalAlarmPayload();
    var globalAlarmForEcoGem = widget.constPvd.getEcoGemPayloadForGlobalAlarm();
    var levelSensorPayload = widget.constPvd.getObjectInConstantPayload(widget.constPvd.level);
    var pumpPayload = widget.constPvd.getObjectInConstantPayload(widget.constPvd.pump);
    var channelPayload = widget.constPvd.getObjectInConstantPayload(widget.constPvd.channel);
    var fertilizerSitePayload = widget.constPvd.getFertilizerSitePayload();
    var waterMeterPayload = widget.constPvd.getObjectInConstantPayload(widget.constPvd.waterMeter);
    var mainValvePayload = widget.constPvd.getObjectInConstantPayload(widget.constPvd.mainValve);
    var valvePayload = widget.constPvd.getObjectInConstantPayload(widget.constPvd.valve);
    var normalCriticalPayload = AppConstants.ecoGemModelList.contains(widget.userData['modelId']) ? widget.constPvd.getNormalCriticalAlarmForEcoGem() : widget.constPvd.getNormalCriticalAlarm();
    var filterPayload = widget.constPvd.getFilterSitePayload();
    bool isGem = AppConstants.gemModelList.contains(widget.constPvd.userData['modelId']);
    bool isNova = AppConstants.ecoGemModelList.contains(widget.constPvd.userData['modelId']);
    bool isOms = AppConstants.omsGemList.contains(widget.constPvd.userData['modelId']);
    var hardwarePayload = {
      "300" : {
        "301" : isOms ? '' : generalPayload,
        if(isGem)
          "302" : mainValvePayload,
        "303" : valvePayload,
        "304" : waterMeterPayload,
        "305" : channelPayload,
        if(isGem)
          "306" : fertilizerSitePayload,
        if(isGem)
          "307" : levelSensorPayload,
        "308" : normalCriticalPayload,
        "309" : pumpPayload,
        "310" : filterPayload,
      }
    };
    return hardwarePayload;
  }

  Widget getHardwareAcknowledgementWidget(HardwareAcknowledgementState state){
    if(state == HardwareAcknowledgementState.notSent){
      return const StatusBox(color:  Colors.black87,child: Text('Do you want to send payload..',),);
    }else if(state == HardwareAcknowledgementState.success){
      return const StatusBox(color:  Colors.green,child: Text('Success..',),);
    }else if(state == HardwareAcknowledgementState.failed){
      return const StatusBox(color:  Colors.red,child: Text('Failed..',),);
    }else if(state == HardwareAcknowledgementState.errorOnPayload){
      return const StatusBox(color:  Colors.red,child: Text('Payload error..',),);
    }else{
      return const SizedBox(
          width: double.infinity,
          height: 5,
          child: LinearProgressIndicator()
      );
    }
  }

  void sendToHttp()async{
    var body = {
      "userId" : widget.userData['customerId'],
      "controllerId" : widget.userData['controllerId'],
      "general": widget.constPvd.general.map((setting) => setting.toJson()).toList(),
      "waterSource": [],
      "levelSensor": widget.constPvd.level.map((setting) => setting.toJson()).toList(),
      "pump": widget.constPvd.pump.map((setting) => setting.toJson()).toList(),
      "filterSite": widget.constPvd.filterSite.map((setting) => setting.toJson()).toList(),
      "filter": widget.constPvd.filter.map((setting) => setting.toJson()).toList(),
      "fertilizerSite": widget.constPvd.fertilizerSite.map((setting) => setting.toJson()).toList(),
      "fertilizerChannel": widget.constPvd.channel.map((setting) => setting.toJson()).toList(),
      "ecPhSensor": widget.constPvd.ecPhSensor.map((setting) => setting.toJson()).toList(),
      "waterMeter": widget.constPvd.waterMeter.map((setting) => setting.toJson()).toList(),
      "pressureSensor": [],
      "mainValve": widget.constPvd.mainValve.map((setting) => setting.toJson()).toList(),
      "valve": widget.constPvd.valve.map((setting) => setting.toJson()).toList(),
      "moistureSensor": widget.constPvd.moisture.map((setting) => setting.toJson()).toList(),
      "analogSensor": [],
      "normalCriticalAlarm": widget.constPvd.normalCriticalAlarm.map((setting) => setting.toJson()).toList(),
      "globalAlarm": widget.constPvd.globalAlarm.map((setting) => setting.toJson()).toList(),
      "hardware" : getConstantHardwarePayload(),
      "controllerReadStatus": "0",
      "createUser" : widget.userData['userId']
    };
    var response = await ConstantRepository().createUserConstant(body);
    print('code : $response');
  }

}

