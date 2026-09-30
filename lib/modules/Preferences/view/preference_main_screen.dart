import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:oro_drip_irrigation/app.dart';
import 'package:oro_drip_irrigation/modules/Preferences/view/view_config.dart';
import 'package:oro_drip_irrigation/services/communication_service.dart';
import 'package:oro_drip_irrigation/services/http_service.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:provider/provider.dart';
import '../../../Constants/constants.dart';
import '../../../Constants/properties.dart' show AppProperties;
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../Widgets/custom_animated_switcher.dart';
import '../../IrrigationProgram/view/schedule_screen.dart';
import '../../IrrigationProgram/widgets/custom_native_time_picker.dart';
import '../model/preference_data_model.dart';
import '../repository/preferences_repo.dart';
import '../state_management/preference_provider.dart';
import '../../SystemDefinitions/widgets/custom_snack_bar.dart';
import '../../../utils/environment.dart';
import '../../IrrigationProgram/view/program_library.dart';
import '../widgets/custom_segmented_control.dart';
import '../widgets/progress_dialog.dart';

final otherSettingsIcons = [
  MdiIcons.lightbulbMultipleOutline,
  MdiIcons.alphaRCircleOutline,
  MdiIcons.alphaYCircleOutline,
  MdiIcons.alphaBCircleOutline,
  MdiIcons.formatLineHeight,
  MdiIcons.windowMinimize,
  MdiIcons.windowMaximize,
  MdiIcons.restart,
  MdiIcons.lightbulbCfl,
  MdiIcons.lightbulbCfl,
  MdiIcons.lightbulbCflOff,
  MdiIcons.toggleSwitch,
  MdiIcons.timerSand,
  MdiIcons.lightbulbCflOff,
  MdiIcons.toggleSwitch,
  MdiIcons.timerSand,
  MdiIcons.motionSensor,
  MdiIcons.lightbulbCflOff,
  MdiIcons.toggleSwitch,
  MdiIcons.timerSand,
  MdiIcons.motionSensor,
  MdiIcons.carBrakeLowPressure,
  MdiIcons.clock,
  MdiIcons.windowMinimize,
  MdiIcons.windowMaximize,
  MdiIcons.carBrakeLowPressure,
  MdiIcons.clock,
];

final voltageSettingsIcons = [
  MdiIcons.speedometerSlow,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
  MdiIcons.speedometer,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
  MdiIcons.scaleUnbalanced,
  MdiIcons.flashTriangle,
  MdiIcons.stepBackward,
  MdiIcons.stepBackward,
  MdiIcons.lightbulbMultiple,
  MdiIcons.scaleUnbalanced,
  MdiIcons.flashTriangle,
  MdiIcons.stepBackward,
  MdiIcons.stepBackward,
];

final timerSettingsIcons = [
  MdiIcons.timerPlay,
  MdiIcons.starCog,
  MdiIcons.battery,
  MdiIcons.batteryClock,
  MdiIcons.messageAlert,
  MdiIcons.timerSettings,
  MdiIcons.radioactive,
  MdiIcons.fanClock,
  MdiIcons.timerSync,
  MdiIcons.timerPlay,
  MdiIcons.timerStop,
  MdiIcons.timerRefresh,
  MdiIcons.timerSand,
  MdiIcons.timerSand,
  MdiIcons.timerSand,
  MdiIcons.timerSand,
];

final currentSettingIcons = [
  MdiIcons.waterAlert,
  MdiIcons.timerSand,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbMultiple,
  MdiIcons.restart,
  MdiIcons.timer,
  MdiIcons.restartAlert,
  MdiIcons.timer,
  MdiIcons.counter,
  Icons.lock_reset,
  MdiIcons.stackOverflow,
  MdiIcons.timerSand,
  MdiIcons.lightbulbGroup,
  MdiIcons.lightbulbMultiple,
  MdiIcons.overscan,
  MdiIcons.overscan,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
  MdiIcons.overscan,
  MdiIcons.overscan,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
  MdiIcons.lightbulbMultiple,
];

final additionalSettingsIcons = [
  MdiIcons.storageTank,
  MdiIcons.bucket,
  MdiIcons.calendar,
  Icons.directions_run,
  MdiIcons.skipNextOutline,
  MdiIcons.storageTank,
  MdiIcons.bucket,
  MdiIcons.calendar,
  Icons.directions_run,
  MdiIcons.skipNextOutline,
];

final levelSettingsIcons = [
  MdiIcons.storageTank,
  MdiIcons.bucket,
  MdiIcons.calendar,
  Icons.directions_run,
  MdiIcons.skipNextOutline,
  MdiIcons.skipNextOutline,
  MdiIcons.bucket,
  MdiIcons.calendar,
  Icons.directions_run,
  MdiIcons.skipNextOutline,
  MdiIcons.skipNextOutline,
];

final voltageCalibrationIcons = [
  MdiIcons.alphaRCircleOutline,
  MdiIcons.alphaYCircleOutline,
  MdiIcons.alphaBCircleOutline,
  MdiIcons.alphaRCircleOutline,
  MdiIcons.alphaYCircleOutline,
  MdiIcons.alphaBCircleOutline,
];

final otherCalibrationIcons = [
  MdiIcons.clipboardFlow,
  Icons.compress,
  MdiIcons.windowMaximize,
  MdiIcons.waterCheck,
  MdiIcons.storeSettings,
  MdiIcons.carCoolantLevel,
  Icons.compress,
  MdiIcons.windowMaximize,
  MdiIcons.waterCheck,
  MdiIcons.storeSettings,
  MdiIcons.carCoolantLevel,
];

class PreferenceMainScreen extends StatefulWidget {
  final int userId, customerId, selectedIndex;
  final Map<String, dynamic> masterData;
  const PreferenceMainScreen({super.key, required this.userId, required this.customerId, required this.masterData, required this.selectedIndex});

  @override
  State<PreferenceMainScreen> createState() => _PreferenceMainScreenState();
}

class _PreferenceMainScreenState extends State<PreferenceMainScreen> with TickerProviderStateMixin{
  late PreferenceProvider preferenceProvider;
  late MqttPayloadProvider mqttPayloadProvider;
  bool shouldSendFailedPayloads = false;
  List oroPumpList = [];
  List selectedOroPumpList = [];
  bool breakLoop = false;
  bool viewConfig = false;
  final PreferenceRepository repository = PreferenceRepository(HttpService());
  late TabController commonPumpTabController;
  late TabController individualPumpTabController;
  int selectedSetting = 0;
  TextEditingController passwordController = TextEditingController();
  final MqttService mqttService = MqttService();
  late bool isToGem;
  late bool isPumpWithValveModel;
  late bool isPumpOnly;
  late bool isValveSetting;
  late bool isNova;
  late bool isWlc;

  @override
  void initState() {
    // TODO: implement initState
    preferenceProvider = Provider.of<PreferenceProvider>(context, listen: false);
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    preferenceProvider.getUserPreference(userId: widget.customerId, controllerId: widget.masterData['controllerId'], modelId: widget.masterData['modelId']).then((_) {
      commonPumpTabController = TabController(
          length: preferenceProvider.commonPumpSettings?.length ?? 0,
          vsync: this
      );
      individualPumpTabController = TabController(
          length: preferenceProvider.individualPumpSetting?.length ?? 0,
          vsync: this
      );
      setState(() {
        if (preferenceProvider.commonPumpSettings?.isEmpty ?? true) {
          selectedSetting = 1;
        }
        if (isValveSetting) {
          selectedSetting = 3;
        }
      });
    });
    preferenceProvider.updateTabIndex(0);
    mqttPayloadProvider.viewSettingsList.clear();
    isToGem = [...AppConstants.gemModelList, ...AppConstants.aquacultureModelList].contains(widget.masterData['modelId']);
    isPumpWithValveModel = AppConstants.pumpWithValveModelList.contains(widget.masterData['modelId']);
    isPumpOnly = AppConstants.pumpModelList.contains(widget.masterData['modelId']);
    isNova = AppConstants.ecoGemAndPlusModelList.contains(widget.masterData['modelId']);
    isWlc = AppConstants.wlcModelList.contains(widget.masterData['modelId']);
    isValveSetting = [1, 2].contains(widget.selectedIndex);
    super.initState();
  }

  @override
  void dispose() {
    preferenceProvider.clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    preferenceProvider = Provider.of<PreferenceProvider>(context, listen:  true);
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: true);

    if(preferenceProvider.commonPumpSettings != null && preferenceProvider.commonPumpSettings!.isNotEmpty) {
      if(oroPumpList.isEmpty) {
        for(var i = 0; i < preferenceProvider.commonPumpSettings!.length; i++){
          oroPumpList.add(preferenceProvider.commonPumpSettings![i].deviceId);
        }
        selectedOroPumpList = oroPumpList;
      }
    }
    if(preferenceProvider.generalData != null && preferenceProvider.commonPumpSettings != null){
      return Scaffold(
        // backgroundColor: Colors.transparent,
        appBar: (MediaQuery.of(context).size.width <= 500 && !isValveSetting)
            ? AppBar(
          title: const Text("Preference"),
          actions: [
            if(selectedSetting == 0)
              FilledButton(
                  onPressed: (){
                    setState(() {
                      viewConfig = !viewConfig;
                    });
                  },
                  child: const Text('View')
              ),
            const SizedBox(width: 10,)
          ],
        )
            : PreferredSize(preferredSize: const Size(0, 0), child: Container()),
        body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: constraints.maxWidth < 700 ? 0: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10,),
                    if(!isValveSetting) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            if(preferenceProvider.commonPumpSettings!.isNotEmpty)
                              if(!viewConfig)
                                Expanded(
                                  child: CustomSegmentedControl(
                                    segmentTitles: const {
                                      0: 'Common setting',
                                      1: 'Individual setting',
                                      2: 'Calibration'
                                    },
                                    groupValue: selectedSetting,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedSetting = value!;
                                        if(selectedSetting == 2) {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Consumer(
                                                    builder: (BuildContext context, PreferenceProvider preferenceProvider, _) {
                                                      return AlertDialog(
                                                        content: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            TextFormField(
                                                              controller: passwordController,
                                                              autofocus: true,
                                                              decoration: const InputDecoration(
                                                                  hintText: "Enter password"
                                                              ),
                                                            ),
                                                            const SizedBox(height: 10,),
                                                            if(preferenceProvider.passwordValidationCode == 404)
                                                              const Text('Invalid password', style: TextStyle(color: Colors.red),)
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                              onPressed: (){
                                                                passwordController.text = "";
                                                                preferenceProvider.updateValidationCode();
                                                                selectedSetting = 1;
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: const Text("CANCEL")
                                                          ),
                                                          TextButton(
                                                              onPressed: () async {
                                                                if (isNova || isToGem) {
                                                                  final pump = preferenceProvider.commonPumpSettings![preferenceProvider.selectedTabIndex];
                                                                  final payload = jsonEncode({"sentSms": "viewconfig,4"});
                                                                  final payload2 = jsonEncode({"0": payload});
                                                                  final viewConfig = {
                                                                    "5900": {"5901": "${pump.serialNumber}+${pump.referenceNumber}+${pump.deviceId}+${pump.interfaceTypeId}+$payload2+${4}"}
                                                                  };
                                                                  mqttService.topicToPublishAndItsMessage(isToGem ? jsonEncode(viewConfig) : payload, "${Environment.mqttPublishTopic}/${preferenceProvider.generalData!.deviceId}");
                                                                }
                                                                await Future.delayed(Duration.zero, () {
                                                                  preferenceProvider.updateValidationCode();
                                                                });
                                                                await preferenceProvider.checkPassword(userId: widget.customerId, password: passwordController.text);
                                                                if(preferenceProvider.passwordValidationCode == 200) {
                                                                  Navigator.of(context).pop();
                                                                  passwordController.text = "";
                                                                }
                                                              },
                                                              // onPressed: () async {
                                                              //   if (isNova || isToGem) {
                                                              //     final pump = preferenceProvider.commonPumpSettings![preferenceProvider.selectedTabIndex];
                                                              //     final payload = jsonEncode({"sentSms": "viewconfig,4"});
                                                              //     final payload2 = jsonEncode({"0": payload});
                                                              //     final viewConfig = {
                                                              //       "5900": {"5901": "${pump.serialNumber}+${pump.referenceNumber}+${pump.deviceId}+${pump.interfaceTypeId}+$payload2+${4}"}
                                                              //     };
                                                              //     final result = await context.read<CommunicationService>().sendCommand(
                                                              //       serverMsg: '',
                                                              //       payload: isToGem ? jsonEncode(viewConfig)
                                                              //           : isWlc ? Constants.sendPayloadWithCrc(payload)
                                                              //           : payload,
                                                              //     );
                                                              //     debugPrint("preference main screen result => $result");
                                                              //     // mqttService.topicToPublishAndItsMessage(
                                                              //     //     ,
                                                              //     //     "${Environment.mqttPublishTopic}/${preferenceProvider.generalData!.deviceId}");
                                                              //   }
                                                              //   await Future.delayed(Duration.zero, () {
                                                              //     preferenceProvider.updateValidationCode();
                                                              //   });
                                                              //   await preferenceProvider.checkPassword(userId: widget.customerId, password: passwordController.text);
                                                              //   if(preferenceProvider.passwordValidationCode == 200) {
                                                              //     Navigator.of(context).pop();
                                                              //     passwordController.text = "";
                                                              //   }
                                                              // },
                                                              child: const Text("OK")
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                );
                                              }
                                          );
                                        } else {
                                          preferenceProvider.updateValidationCode();
                                        }
                                      });
                                    },
                                  ),
                                )
                              else
                                Expanded(child: Container()),
                            if(preferenceProvider.commonPumpSettings!.isNotEmpty && constraints.maxWidth >= 700)
                              const SizedBox(width: 50,),
                            if(constraints.maxWidth >= 700)
                              Expanded(
                                child: _getDefaultTabController(),
                              ),
                            if(selectedSetting == 0 && MediaQuery.of(context).size.width > 500 && preferenceProvider.commonPumpSettings!.isNotEmpty)
                              FilledButton(
                                  onPressed: (){
                                    setState(() {
                                      viewConfig = !viewConfig;
                                    });
                                  },
                                  child: const Text('View')
                              )
                          ],
                        ),
                      ),
                    ],
                    if(constraints.maxWidth <= 700 && !isValveSetting)
                      _getDefaultTabController(),
                    if(!isValveSetting)
                      const SizedBox(height: 10,),
                    if(selectedSetting != 2)
                      Expanded(
                          child: TabBarView(
                            controller: selectedSetting != 1 ? commonPumpTabController : individualPumpTabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              if(viewConfig)
                                for(int i = 0; i < commonPumpTabController.length; i++)
                                  ViewConfig(
                                    userId: widget.userId,
                                    isLora: preferenceProvider.commonPumpSettings![commonPumpTabController.index].interfaceTypeId == 1,
                                    modelId: widget.masterData['modelId'],
                                  )
                              else if(selectedSetting == 0)
                                for(var commonSettingIndex = 0; commonSettingIndex < preferenceProvider.commonPumpSettings!.length; commonSettingIndex++)
                                  buildSettingsCategory(
                                      context: context,
                                      settingList: preferenceProvider.commonPumpSettings![commonSettingIndex].settingList,
                                      constraints: constraints,
                                      pumpIndex: commonSettingIndex
                                  )
                              else if(selectedSetting == 1)
                                  for(var pumpSettingIndex = 0; pumpSettingIndex < preferenceProvider.individualPumpSetting!.length; pumpSettingIndex++)
                                    buildSettingsCategory(
                                        context: context,
                                        settingList: preferenceProvider.individualPumpSetting![pumpSettingIndex].settingList,
                                        constraints: constraints,
                                        pumpIndex: pumpSettingIndex
                                    )
                              /* else if(selectedSetting == 3 && isValveSetting)
                                ValveSettings(
                                  masterData: widget.masterData,
                                  selectedMode: widget.selectedIndex,
                                )
                              else if(selectedSetting == 3)
                                const MoistureSettings()*/
                            ],
                          )
                      ),
                    if(selectedSetting == 2 && (preferenceProvider.passwordValidationCode == 200))
                      Expanded(
                          child: TabBarView(
                            controller: selectedSetting != 1 ? commonPumpTabController : individualPumpTabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for(var calibrationSettingIndex = 0; calibrationSettingIndex < preferenceProvider.calibrationSetting!.length; calibrationSettingIndex++)
                                buildSettingsCategory(
                                    context: context,
                                    settingList: preferenceProvider.calibrationSetting![calibrationSettingIndex].settingList,
                                    constraints: constraints,
                                    pumpIndex: calibrationSettingIndex
                                )
                            ],
                          )
                      ),
                  ],
                ),
              );
            }
        ),
        floatingActionButton: !viewConfig ? Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if(!isValveSetting)...[
              if(preferenceProvider.passwordValidationCode == 200 && preferenceProvider.calibrationSetting![0].settingList[1].controllerReadStatus == "0"
                  ? getCalibrationPayload(isToGem: isToGem).split(';')[0].isNotEmpty
                  : getFailedPayload(sendAll: false, isToGem: isToGem).split(';')[0].isNotEmpty)
              // if(preferenceProvider.commonPumpSettings!.isNotEmpty ? ((preferenceProvider.commonPumpSettings?.any((element) => element.settingList.any((e) => e.controllerReadStatus == "0")) ?? false) || (preferenceProvider.individualPumpSetting?.any((element) => element.settingList.any((e) => e.controllerReadStatus == "0")) ?? false)) : false)
                MaterialButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  color: Colors.orange.shade300,
                  onPressed: () async {
                    final failedPayload = preferenceProvider.passwordValidationCode == 200
                        ? getCalibrationPayload(isToGem: isToGem).split(';')
                        : getFailedPayload(sendAll: false, isToGem: isToGem).split(';');
                    // print(failedPayload);
                    List temp = List.from(selectedOroPumpList);
                    preferenceProvider.temp.clear();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                            builder: (BuildContext context, StateSetter stateSetter) {
                              return AlertDialog(
                                content: SizedBox(
                                  height: 450,
                                  width: 300,
                                  // padding: EdgeInsets.all(16),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        for (var i = 0; i < preferenceProvider.commonPumpSettings!.length; i++)
                                          CheckboxListTile(
                                              title: Text(preferenceProvider.commonPumpSettings![i].deviceName),
                                              subtitle: Text(preferenceProvider.commonPumpSettings![i].deviceId),
                                              value: temp.contains(preferenceProvider.commonPumpSettings![i].deviceId),
                                              onChanged: (newValue) {
                                                stateSetter(() {
                                                  setState(() {
                                                    if (temp.contains(preferenceProvider.commonPumpSettings![i].deviceId)) {
                                                      temp.remove(preferenceProvider.commonPumpSettings![i].deviceId);
                                                    } else {
                                                      temp.add(preferenceProvider.commonPumpSettings![i].deviceId);
                                                    }
                                                  });
                                                });
                                              }
                                          ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: failedPayload.length,
                                          itemBuilder: (BuildContext context, int i) {
                                            var payloadToDecode = isToGem ? failedPayload[i].split('+')[4] : failedPayload[i];
                                            var decodedData = jsonDecode(payloadToDecode);
                                            var key = decodedData.keys.first;
                                            int oroPumpIndex = 0;
                                            if (isToGem) {
                                              oroPumpIndex = preferenceProvider.commonPumpSettings!.indexWhere((element) => element.deviceId == failedPayload[i].split('+')[2]);
                                            }
                                            return temp.contains(preferenceProvider.commonPumpSettings![oroPumpIndex].deviceId) ? ListTile(
                                              leading: Container(
                                                height: 30,
                                                width: 30,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: AppProperties.linearGradientLeading,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${i + 1}',
                                                    style: const TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                preferenceProvider.commonPumpSettings![oroPumpIndex].deviceName,
                                                style: const TextStyle(fontWeight: FontWeight.w400),
                                              ),
                                              subtitle: Text(
                                                statusMessages[key]!,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ) : Container();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  FilledButton(
                                      onPressed: temp.isNotEmpty ? () async {
                                        await Future.delayed(Duration.zero, () {
                                          setState(() {
                                            shouldSendFailedPayloads = true;
                                            selectedOroPumpList = List.from(temp);
                                          });
                                        });
                                        Navigator.pop(context);
                                        await sendFunction();
                                      } : null,
                                      child: const Text("Resend")
                                  ),
                                  FilledButton(
                                      onPressed: (){
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Cancel")
                                  )
                                ],
                              );
                            }
                        );
                      },
                    );
                  },
                  child: const Text("Failed", style: TextStyle(color: Colors.black),),
                ),
              const SizedBox(width: 20,),
            ],
            MaterialButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)
              ),
              color: Theme.of(context).primaryColor,
              onPressed: () async {
                final rtcError = validateAllRtcSettings();
                print("rtcError : ${rtcError}");
                if (rtcError != null) {
                  _showRtcErrorDialog(rtcError);
                  return;
                }
                await Future.delayed(Duration.zero, () {
                  setState(() {
                    // oroPumpList.clear();
                    shouldSendFailedPayloads = false;
                  });
                });
                preferenceProvider.temp.clear();
                if(preferenceProvider.commonPumpSettings!.isEmpty || preferenceProvider.commonPumpSettings!.length <= 1) {
                  sendFunction();
                } else {
                  if(preferenceProvider.passwordValidationCode == 200) {
                    if(preferenceProvider.calibrationSetting!.any((element) => element.settingList.any((e) => e.changed == true))) {
                      selectedOroPumpList.clear();
                      if(selectedOroPumpList.isEmpty) {
                        selectedOroPumpList.addAll(preferenceProvider.calibrationSetting!.where((element) => element.settingList.any((e) => e.changed == true)).toList().map((e) =>e.deviceId).toList());
                      }
                      sendFunction();
                    } else {
                      selectPumpToSend();
                    }
                  } else {
                    List common = preferenceProvider.commonPumpSettings!.where((element) =>
                        element.settingList.any((e) => e.changed == true)).toList().map((e) =>e.deviceId).toList();
                    List individual = preferenceProvider.individualPumpSetting!.where((element) =>
                        element.settingList.any((e) => e.changed == true)).toList().map((e) =>e.deviceId).toList();;
                    if(preferenceProvider.commonPumpSettings!.any((element) => element.settingList.any((e) => e.changed == true)) || preferenceProvider.individualPumpSetting!.any((element) => element.settingList.any((e) => e.changed == true))) {
                      selectedOroPumpList.clear();
                      if(selectedOroPumpList.isEmpty) {
                        selectedOroPumpList.addAll(common.isNotEmpty ? common : individual);
                      }
                      sendFunction();
                    } else {
                      selectPumpToSend();
                    }
                  }
                }
              },
              child: Text(preferenceProvider.passwordValidationCode == 200
                  ? "Send calibration"
                  : isValveSetting
                  ? "Send"
                  : "Send preference", style: const TextStyle(color: Colors.white),),
            ),
          ],
        ) : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    }
    else {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(semanticsLabel: "Loading")
        ),
      );
    }
  }

  Widget _getDefaultTabController() {
    return DefaultTabController(
      length: selectedSetting != 1 ? preferenceProvider.commonPumpSettings!.length: preferenceProvider.individualPumpSetting!.length,
      child: Column(
        children: [
          const SizedBox(height: 10,),
          Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: selectedSetting != 1 ? commonPumpTabController : individualPumpTabController,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
              indicatorColor: Colors.white,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.white,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal,color: Colors.grey.shade400),
              dividerColor: Colors.transparent,
              isScrollable: true,
              onTap: (value) async{
                preferenceProvider.updateTabIndex(commonPumpTabController.index);
                if(selectedSetting == 2 && isToGem) {
                  mqttPayloadProvider.viewSettingsList.clear();
                  final oroPumpSerialNumber = preferenceProvider.commonPumpSettings![commonPumpTabController.index].serialNumber;
                  final referenceNumber = preferenceProvider.commonPumpSettings![commonPumpTabController.index].referenceNumber;
                  final deviceId = preferenceProvider.commonPumpSettings![commonPumpTabController.index].deviceId;
                  final interfaceType = preferenceProvider.commonPumpSettings![commonPumpTabController.index].interfaceTypeId;
                  final categoryId = preferenceProvider.commonPumpSettings![commonPumpTabController.index].categoryId;
                  final payload = jsonEncode({"sentSms": "viewconfig"});
                  final payload2 = jsonEncode({"0": payload});
                  final viewConfig = {"5900": {
                    "5901": "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload2+$categoryId",
                  }};
                  final result = await context.read<CommunicationService>().sendCommand(
                    serverMsg: '',
                    payload: isWlc ? Constants.sendPayloadWithCrc(payload) : jsonEncode(viewConfig),
                  );
                  // mqttService.topicToPublishAndItsMessage(isWlc ? Constants.sendPayloadWithCrc(payload) : jsonEncode(viewConfig),
                  //     "${Environment.mqttPublishTopic}/${widget.masterData['deviceId']}");
                }
              },
              tabs: [
                if(selectedSetting != 1)
                  ...preferenceProvider.commonPumpSettings!.asMap().entries.map((entry) {
                    final element = entry.value;
                    return preferenceProvider.commonPumpSettings!.length > 1 ? Tab(
                      text: "${element.deviceName}\n${element.deviceId}",
                    ) : Container();
                  })
                else
                  ...preferenceProvider.individualPumpSetting!.asMap().entries.map((entry) {
                    final element = entry.value;

                    CommonPumpSetting? matchingCommonPump;
                    try {
                      matchingCommonPump = preferenceProvider.commonPumpSettings!
                          .firstWhere((common) => common.deviceId == element.deviceId);
                    } catch (e) {
                      matchingCommonPump = null;
                    }

                    return preferenceProvider.individualPumpSetting!.length > 1 ? Tab(
                      text: (preferenceProvider.commonPumpSettings!.length > 1 &&
                          matchingCommonPump != null)
                          ? "${element.name}\n${matchingCommonPump.deviceId}"
                          : element.name,
                    ) : Container();
                  })
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSettingsCategory({required BuildContext context, required List<SettingList> settingList, required BoxConstraints constraints, required int pumpIndex}) {
    try {
      return SingleChildScrollView(
        child: Column(
          children: [
            Wrap(
              children: [
                for(var categoryIndex = 0; categoryIndex < settingList.length; categoryIndex++)
                  if([
                    ...AppConstants.wlcModelList
                  ].contains(widget.masterData['modelId']) && AppConstants.otherCalibration.contains(settingList[categoryIndex].type))
                    Container()
                  else if([
                    ...AppConstants.singlePhaseWlcModelList,
                    ...AppConstants.threePhaseWlcModelList,
                  ].contains(widget.masterData['modelId']) && AppConstants.otherSetting.contains(settingList[categoryIndex].type))
                    Container()
                  else if([
                      ...AppConstants.singleOrThreePhaseWlcModelList,
                    ].contains(widget.masterData['modelId']) && AppConstants.additionalSetting.contains(settingList[categoryIndex].type))
                      Container()
                    else if((AppConstants.levelSetting.contains(settingList[categoryIndex].type) && isToGem) ? preferenceProvider.individualPumpSetting![pumpIndex].controlGem : true)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          width: constraints.maxWidth < 700 ? constraints.maxWidth : (constraints.maxWidth/2) - 40,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IntrinsicWidth(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  height: 30,
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColorLight,
                                      borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(3))
                                  ),
                                  child: Center(
                                    child: Text(
                                      settingList[categoryIndex].name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white,),
                                    ),
                                  ),
                                ),
                              ),
                              // Text(settingList[categoryIndex].name, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),),
                              // const SizedBox(height: 10,),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                                    color: Colors.white,
                                    border: Border.all(color: Theme.of(context).primaryColorLight, width: 0.3)
                                  // boxShadow: AppProperties.customBoxShadowLiteTheme
                                ),
                                child: Column(
                                  children: [
                                    for(var settingIndex = 0; settingIndex < settingList[categoryIndex].setting.length; settingIndex++)
                                      if(settingList[categoryIndex].setting[settingIndex].title.toUpperCase() == "RTC TIMER")
                                        _buildRtcTimer(categoryIndex, settingIndex, pumpIndex, settingList)
                                      else if(settingList[categoryIndex].setting[settingIndex].title.toUpperCase() == "2 PHASE"
                                          || settingList[categoryIndex].setting[settingIndex].title.toUpperCase() == "AUTO RESTART 2 PHASE"
                                          || (settingList[categoryIndex].setting[settingIndex].title.toUpperCase() == "AUTO RESTART" && settingList[categoryIndex].setting[settingIndex].serialNumber == 8)
                                          || (isNova && (
                                              settingList[categoryIndex].setting[settingIndex].title.toUpperCase() == "UPPER TANK LINEAR LEVEL SENSOR" ||
                                                  settingList[categoryIndex].setting[settingIndex].title.toUpperCase() == "LOWER TANK LINEAR LEVEL SENSOR"
                                          ))
                                      )
                                        _buildTwoPhaseCard(categoryIndex, settingIndex, pumpIndex, settingList)
                                      else
                                        buildCustomListTileWidget(
                                          context: context,
                                          title: settingList[categoryIndex].setting[settingIndex].title,
                                          widgetType: _getWidgetType(categoryIndex, settingIndex, settingList),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.deny(RegExp('[^0-9.]')),
                                            LengthLimitingTextInputFormatter(6),
                                          ],
                                          dataList: settingList[categoryIndex].setting[settingIndex].title.toUpperCase() == "SENSOR HEIGHT"
                                              ? ["20", "35"] : settingList[categoryIndex].setting[settingIndex].title.toUpperCase() == 'CABLE SELECT' ? ['0', '1', '2', '3'] : ["10", "12"],
                                          value: _getInitialValue(categoryIndex, settingIndex, settingList, pumpIndex),
                                          leading: _buildLeading(categoryIndex, settingIndex, settingList),
                                          onValueChange: (newValue) => onChangeValue(categoryIndex, settingIndex, settingList, newValue),
                                          conditionToShow: getConditionToShow(type: settingList[categoryIndex].type, serialNumber: settingList[categoryIndex].setting[settingIndex].serialNumber, value: settingList[categoryIndex].setting[settingIndex].value,),
                                          subTitle: _getSubTitle(categoryIndex, settingIndex, settingList, pumpIndex),
                                          display: settingList[categoryIndex].setting[settingIndex].display,
                                          hidden: (settingList[categoryIndex].setting[settingIndex].title == "Schedule by Days"
                                              || (!isNova && AppConstants.otherCalibration.contains(settingList[categoryIndex].type) && [7,8].contains(settingList[categoryIndex].setting[settingIndex].serialNumber)))
                                              ? true
                                              : settingList[categoryIndex].setting[settingIndex].hidden,
                                          enabled: true, modelId: widget.masterData['modelId'],
                                        )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10,),
                              if(categoryIndex == settingList.length - 1)
                                const SizedBox(height: 50,)
                            ],
                          ),
                        ),
                for(var categoryIndex = 0; categoryIndex < settingList.length; categoryIndex++)
                  if(!((AppConstants.levelSetting.contains(settingList[categoryIndex].type) && isToGem) ? preferenceProvider.individualPumpSetting![pumpIndex].controlGem : true))
                    const SizedBox(height: 50,)
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      );
    } catch(error, stackTrace) {
      // throw Exception('This is a test exception');
      print("error ==> $error");
      print("stackTrace ==> $stackTrace");
      return const Center(child: Text("Unexpected error"));
    }
  }

  Widget _buildLeading(int categoryIndex, int settingIndex, List settingList) {
    return Container(
        decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white
          // gradient: linearGradientLeading,
        ),
        child: CircleAvatar(
            backgroundColor: cardColor,
            child: _buildIcon(categoryIndex, settingIndex, settingList)
        )
    );
  }

  int _rtcTimeToSeconds(String timeStr) {
    if (timeStr.isEmpty) return 0;
    final parts = timeStr.split(':');
    if (parts.length < 2) return 0;
    int hours = int.tryParse(parts[0]) ?? 0;
    int minutes = int.tryParse(parts[1]) ?? 0;
    int seconds = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    return hours * 3600 + minutes * 60 + seconds;
  }

  String? _validateSingleRtcList(List<RtcTimeSetting> rtcSettings, {String? pumpName, bool isLiveEdit = false}) {
    int? lastActiveOffTimeSeconds;
    int? lastActiveIndex;

    for (int i = 0; i < rtcSettings.length; i++) {
      final rtc = rtcSettings[i];
      final onSeconds = _rtcTimeToSeconds(rtc.onTime);
      final offSeconds = _rtcTimeToSeconds(rtc.offTime);

      if (onSeconds == 0 && offSeconds == 0) {
        continue;
      }

      final prefix = pumpName != null ? "$pumpName - RTC ${i + 1}" : "RTC ${i + 1}";

      if (offSeconds > 0 || !isLiveEdit) {
        if (offSeconds <= onSeconds) {
          return "$prefix: Off time must be greater than On time.";
        }
      }

      if (lastActiveOffTimeSeconds != null && onSeconds < lastActiveOffTimeSeconds) {
        final prevPrefix = "RTC ${lastActiveIndex! + 1}";
        return "$prefix: On time must be greater than or equal to $prevPrefix Off time.";
      }

      if (offSeconds > 0) {
        lastActiveOffTimeSeconds = offSeconds;
        lastActiveIndex = i;
      }
    }
    return null;
  }

  void _showRtcErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text("Invalid RTC Setting"),
            ],
          ),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String? validateAllRtcSettings() {
    if (preferenceProvider.individualPumpSetting != null) {
      for (var individualPump in preferenceProvider.individualPumpSetting!) {
        final pumpName = preferenceProvider.individualPumpSetting!.length > 1 ? individualPump.name : null;
        for (var settingCategory in individualPump.settingList) {
          if (AppConstants.timerSetting.contains(settingCategory.type)) {
            bool isRtcEnabled = true;
            List<RtcTimeSetting>? rtcSettings;

            for (var setting in settingCategory.setting) {
              if (setting.title.toUpperCase() == "RTC") {
                isRtcEnabled = setting.value == true;
              }
              if (setting.title.toUpperCase() == "RTC TIMER" && setting.rtcSettings != null) {
                rtcSettings = setting.rtcSettings;
              }
            }

            if (isRtcEnabled && rtcSettings != null) {
              final error = _validateSingleRtcList(rtcSettings, pumpName: pumpName);
              if (error != null) {
                return error;
              }
            }
          }
        }
      }
    }

    if (preferenceProvider.commonPumpSettings != null) {
      for (var commonSetting in preferenceProvider.commonPumpSettings!) {
        for (var settingCategory in commonSetting.settingList) {
          if (AppConstants.timerSetting.contains(settingCategory.type)) {
            bool isRtcEnabled = true;
            List<RtcTimeSetting>? rtcSettings;

            for (var setting in settingCategory.setting) {
              if (setting.title.toUpperCase() == "RTC") {
                isRtcEnabled = setting.value == true;
              }
              if (setting.title.toUpperCase() == "RTC TIMER" && setting.rtcSettings != null) {
                rtcSettings = setting.rtcSettings;
              }
            }

            if (isRtcEnabled && rtcSettings != null) {
              final error = _validateSingleRtcList(rtcSettings);
              if (error != null) {
                return error;
              }
            }
          }
        }
      }
    }

    return null;
  }

  Widget _buildRtcTimer(int categoryIndex, int settingIndex, int pumpIndex, List settingList) {
    final rtcSettings = settingList[categoryIndex].setting[settingIndex].rtcSettings as List<RtcTimeSetting>?;

    return CustomAnimatedSwitcher(
      condition: (conditions['rtc'] ?? false),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: Center(child: Text('RTC', style: Theme.of(context).textTheme.bodyLarge))),
              Expanded(child: Center(child: Text('On Time', style: Theme.of(context).textTheme.bodyLarge))),
              Expanded(child: Center(child: Text('Off Time', style: Theme.of(context).textTheme.bodyLarge))),
            ],
          ),
          const SizedBox(height: 20,),
          Column(
            children: [
              if (rtcSettings != null)
                ...rtcSettings.asMap().entries.map((entry) {
                  final int rtcIndex = entry.key;
                  final rtcSetting = entry.value;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                '${rtcIndex + 1}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: CustomNativeTimePicker(
                                initialValue: rtcSetting.onTime.isNotEmpty ? rtcSetting.onTime : "00:00:00",
                                onChanged: (newTime) {
                                  final oldTime = rtcSetting.onTime;
                                  rtcSetting.onTime = newTime;
                                  final error = _validateSingleRtcList(rtcSettings, isLiveEdit: true);
                                  if (error != null) {
                                    rtcSetting.onTime = oldTime;
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      if (mounted) _showRtcErrorDialog(error);
                                    });
                                    setState(() {});
                                  } else {
                                    setState(() {
                                      settingList[categoryIndex].setting[settingIndex].isChanged = true;
                                      settingList[categoryIndex].changed = true;
                                    });
                                  }
                                },
                                is24HourMode: true, modelId: 1,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: CustomNativeTimePicker(
                                initialValue: rtcSetting.offTime.isNotEmpty ? rtcSetting.offTime : "00:00:00",
                                onChanged: (newTime) {
                                  final oldTime = rtcSetting.offTime;
                                  rtcSetting.offTime = newTime;
                                  final error = _validateSingleRtcList(rtcSettings, isLiveEdit: true);
                                  if (error != null) {
                                    rtcSetting.offTime = oldTime;
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      if (mounted) _showRtcErrorDialog(error);
                                    });
                                    setState(() {});
                                  } else {
                                    setState(() {
                                      settingList[categoryIndex].changed = true;
                                    });
                                  }
                                },
                                is24HourMode: true, modelId: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],
                  );
                }),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTwoPhaseCard(int categoryIndex, int settingIndex, int pumpIndex, List settingList) {
    bool singlePhaseModel = [
      ...AppConstants.singlePhasePumpModel,
      ...AppConstants.singlePhasePumpPlusModel,
      ...AppConstants.singlePhaseShineModel,
      ...AppConstants.singlePhaseElitePlusModel,
      ...AppConstants.singlePhaseEcoGemModel,
      ...AppConstants.singlePhaseEcoGemPlusModel].contains(widget.masterData['modelId']);
    bool showTitle = true;
    bool showPumpList = true;
    if(singlePhaseModel){
      if(settingList[categoryIndex].setting[settingIndex].title.contains("2 Phase")){
        showTitle = false;
        showPumpList = false;
      }
    }
    return Column(
      children: [
        if(showTitle)
          ListTile(
            leading: Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white
                  // gradient: linearGradientLeading,
                ),
                child: CircleAvatar(
                    backgroundColor: cardColor,
                    child: Icon(otherSettingsIcons[settingIndex], color: Theme.of(context).primaryColor)
                )
            ),
            title: Text(settingList[categoryIndex].setting[settingIndex].title, style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).primaryColorLight, fontWeight: FontWeight.bold),),
          ),
        if(showPumpList)
          Column(
            children: [
              for (int index = 0; index < (isToGem ? preferenceProvider.individualPumpSetting!
                  .where((e) => e.deviceId == preferenceProvider.commonPumpSettings![pumpIndex].deviceId).length : preferenceProvider.individualPumpSetting!.length); index++)
                SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    secondary: const SizedBox(
                      width: 40,
                      height: 40,
                    ),
                    title: Text(isToGem ? preferenceProvider.individualPumpSetting!
                        .where((e) => e.deviceId == preferenceProvider.commonPumpSettings![pumpIndex].deviceId)
                        .elementAt(index)
                        .name : preferenceProvider.individualPumpSetting![index].name),
                    value: settingList[categoryIndex].setting[settingIndex].value[index],
                    onChanged: (newValue) {
                      setState(() {
                        settingList[categoryIndex].setting[settingIndex].value[index] = newValue;
                        settingList[categoryIndex].setting[settingIndex].isChanged = true;
                        settingList[categoryIndex].changed = true;
                      });
                    }
                ),
            ],
          )
      ],
    );
  }

  int _getWidgetType(int categoryIndex, int settingIndex, List settingList) {
    return (settingList[categoryIndex].setting[settingIndex].title.toUpperCase() == "PRESSURE MAXIMUM VALUE")
        ? 7
        : settingList[categoryIndex].setting[settingIndex].widgetTypeId;
  }

  Widget _buildIcon(int categoryIndex, int settingIndex, List settingList) {
    return Icon(
        (AppConstants.otherSetting.contains(settingList[categoryIndex].type))
            ? otherSettingsIcons[settingIndex]
            : (AppConstants.voltageSetting.contains(settingList[categoryIndex].type))
            ? voltageSettingsIcons[settingIndex]
            : (AppConstants.timerSetting.contains(settingList[categoryIndex].type))
            ? timerSettingsIcons[settingIndex]
            : (AppConstants.currentSetting.contains(settingList[categoryIndex].type))
            ? currentSettingIcons[settingIndex]
            : (AppConstants.currentCalibration.contains(settingList[categoryIndex].type))
            ? voltageCalibrationIcons[settingIndex]
            : (AppConstants.otherCalibration.contains(settingList[categoryIndex].type))
            ? otherCalibrationIcons[settingIndex]
            : AppConstants.levelSetting.contains(settingList[categoryIndex].type)
            ? levelSettingsIcons[settingIndex]
            : [211, 611].contains(settingList[categoryIndex].type)
            ? Icons.numbers
            : additionalSettingsIcons[settingIndex],
        color: Theme.of(context).primaryColor
    );
  }

  dynamic _getSubTitle(
      int categoryIndex,
      int settingIndex,
      List settingList,
      int pumpIndex,
      ) {
    // Debug logs

    // Condition check
    if (!(isNova || isToGem) ||
        ![...AppConstants.voltageCalibration, ...AppConstants.currentCalibration, ...AppConstants.otherCalibration].contains(settingList[categoryIndex].type)) {
      return null;
    }

    // Get value once
    final value = _getValue(
      type: settingList[categoryIndex].type,
      categoryIndex: categoryIndex,
      pumpIndex: pumpIndex,
      settingIndex: settingIndex,
    );

    // Handle empty value
    if (value.isEmpty) {
      return "Last setting: Loading...";
    }

    // Split values
    final parts = value.split(',');

    // Safe index calculation
    int index = 0;

    if (categoryIndex == 0 || categoryIndex == 1) {
      index = (settingIndex < 3) ? settingIndex : 0;
    } else {
      index = (settingIndex < parts.length) ? settingIndex : 0;
    }

    // Final return
    return "Last setting: ${parts[index]}";
  }

  dynamic _getInitialValue(int categoryIndex, int settingIndex, List settingList, int pumpIndex) {
    return settingList[categoryIndex].setting[settingIndex].value;
  }

  void onChangeValue(int categoryIndex, int settingIndex, List settingList, newValue) {
    setState(() {
      settingList[categoryIndex].setting[settingIndex].isChanged = true;
      if(AppConstants.otherSetting.contains(settingList[categoryIndex].type)) {
        if (settingList[categoryIndex].setting[settingIndex].serialNumber == 15 ||
            settingList[categoryIndex].setting[settingIndex].serialNumber == 16) {
          if (settingList[categoryIndex].setting[settingIndex].serialNumber == 15) {
            settingList[categoryIndex].setting[settingIndex].value = true;
            settingList[categoryIndex].setting.firstWhere((setting) => setting.serialNumber == 16).value = false;
          } else if (settingList[categoryIndex].setting[settingIndex].serialNumber == 16) {
            settingList[categoryIndex].setting[settingIndex].value = true;
            settingList[categoryIndex].setting.firstWhere((setting) => setting.serialNumber == 15).value = false;
          }
        }
      }
      if(settingList[categoryIndex].type == 211 && settingList[categoryIndex].setting[settingIndex].serialNumber == 5) {
        if(settingList[categoryIndex].setting[settingIndex].value) {
          preferenceProvider.mode == "Manual";
        } else {
          preferenceProvider.mode == "Duration";
        }
      }
      settingList[categoryIndex].changed = true;
      settingList[categoryIndex].setting[settingIndex].value = newValue;
    });
  }

  List<String> extractValues(int rtcIndex, List<String> valuesList) {
    int startIndex = rtcIndex * 2;
    return valuesList.sublist(startIndex, startIndex + 2);
  }

  String _getValue({required int type, required int categoryIndex, required int pumpIndex, required int settingIndex}) {
    String valueToShow = "";

    for (var i = 0; i < mqttPayloadProvider.viewSettingsList.length; i++) {
      if(i == 0) {
        var decodedList = jsonDecode(mqttPayloadProvider.viewSettingsList[i]);
        for (var element in decodedList) {
          Map<String, dynamic> decode = element;
          decode.forEach((key, value) {
            if (AppConstants.voltageCalibration.contains(type)) {
              if (key == "calibration") {
                valueToShow = value;
              }
            } else if (AppConstants.currentCalibration.contains(type)) {
              if (key == "calibration") {
                valueToShow = value.split(',').skip(3).join(',');
              }
            } else if (AppConstants.otherCalibration.contains(type)) {
              if (key == "calibration") {
                valueToShow = value.split(',').skip(6).join(',');
              }
            }

          });
        }
      }
    }

    return valueToShow;
  }

  String getValueForRtc({required int type, required int categoryIndex, required int pumpIndex, required int settingIndex}) {
    String valueToShow = "";

    for (var i = 0; i < mqttPayloadProvider.viewSettingsList.length; i++) {
      if(i-1 == pumpIndex) {
        var rtcTimeTemp = "";
        var delayTimeTemp = "";
        var decodedList = jsonDecode(mqttPayloadProvider.viewSettingsList[i]);
        for (var element in decodedList) {
          Map<String, dynamic> decode = element;
          decode.forEach((key, value) {
            switch (type) {
              case 202:
                if (key == "rtcconfig") rtcTimeTemp = value;
                valueToShow = delayTimeTemp+rtcTimeTemp;
                break;
            }
          });
        }
      }
    }
    return valueToShow;
  }

  Map<String, bool> conditions = {
    'phaseValue': true,
    'lowVoltage': false,
    'highVoltage': false,
    'startingCapacitor': false,
    'starterFeedback': false,
    'maxTime': false,
    'cyclicTime': false,
    'rtc': false,
    'dryRun': false,
    'dryRunRestart': false,
    'dryRunOcc': false,
    'overLoad': false,
    'schedule': false,
    'light': false,
    'peakHour': false,
  };

  bool getConditionToShow({required int type, required int serialNumber, required value}) {
    bool result = true;
    void setCondition(String key) {
      conditions[key] = value;
    }
    if (AppConstants.otherSetting.contains(type)) {
      // if (serialNumber == 1) setCondition('phaseValue');
      if (serialNumber == 9) setCondition('light');
      if (serialNumber == 12) setCondition('peakHour');
      if ([10, 11].contains(serialNumber)) result = conditions['light']!;
      if ([13, 14].contains(serialNumber)) result = conditions['peakHour']!;
    } else if (AppConstants.voltageSetting.contains(type)) {
      if (serialNumber == 1) setCondition('lowVoltage');
      if (serialNumber == 6) setCondition('highVoltage');
      if ([2, 3].contains(serialNumber)) result = conditions['lowVoltage']!;
      if ([4, 5].contains(serialNumber)) {
        result = conditions['phaseValue']! && conditions['lowVoltage']!;
      }
      if ([7, 8].contains(serialNumber)) result = conditions['highVoltage']!;
      if ([9, 10].contains(serialNumber)) {
        result = conditions['phaseValue']! && conditions['highVoltage']!;
      }
    } else if (AppConstants.timerSetting.contains(type)) {
      if (serialNumber == 3) setCondition('startingCapacitor');
      if (serialNumber == 4) result = conditions['startingCapacitor']!;
      if (serialNumber == 5) setCondition('starterFeedback');
      if (serialNumber == 6) result = conditions['starterFeedback']!;
      if (serialNumber == 7) setCondition('maxTime');
      if (serialNumber == 8) result = conditions['maxTime']!;
      if (serialNumber == 9) setCondition('cyclicTime');
      if ([10, 11].contains(serialNumber)) result = conditions['cyclicTime']!;
      if (serialNumber == 12) setCondition('rtc');
      if (serialNumber == 13) result = conditions['rtc']!;
    } else if (AppConstants.currentSetting.contains(type)) {
      if (serialNumber == 1) setCondition('dryRun');
      if (serialNumber == 4) {
        result = conditions['phaseValue']! && conditions['dryRun']!;
      }
      if ([2, 3, 5, 6, 7, 8, 9, 10].contains(serialNumber)) {
        result = conditions['dryRun']!;
      }
      if (serialNumber == 5) setCondition('dryRunRestart');
      if (serialNumber == 6) {
        result = conditions['dryRun']! && conditions['dryRunRestart']!;
      }
      if (serialNumber == 7) setCondition('dryRunOcc');
      if ([8, 9].contains(serialNumber)) {
        result = conditions['dryRun']! && conditions['dryRunOcc']!;
      }
      if (serialNumber == 11) setCondition('overLoad');
      if (serialNumber == 14) {
        result = conditions['phaseValue']! && conditions['overLoad']!;
      }
      if ([12, 13, 15].contains(serialNumber)) result = conditions['overLoad']!;
    } else if (AppConstants.additionalSetting.contains(type)) {
      if (serialNumber == 3) setCondition('schedule');
      if ([4, 5].contains(serialNumber)) result = conditions['schedule']!;
    }

    print("result => $result");
    return result;
  }

  Widget buildTabItem({required int index, required String itemName, required int selectedIndex}) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: index == selectedIndex ? Theme.of(context).primaryColor : cardColor
        ),
        child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(itemName, style: TextStyle(color: index == selectedIndex ? Colors.white : Theme.of(context).primaryColor),),
            )
        )
    );
  }

  void selectPumpToSend() {
    showAdaptiveDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter stateSetter) {
                return AlertDialog(
                  title: const Text("Select the pump"),
                  content: SizedBox(
                    height: 200,
                    child: Scrollbar(
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for(var i = 0; i < preferenceProvider.commonPumpSettings!.length; i++)
                              CheckboxListTile(
                                  dense: false,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                                  title: Text(preferenceProvider.commonPumpSettings![i].deviceName),
                                  subtitle: Text(preferenceProvider.commonPumpSettings![i].deviceId),
                                  value: selectedOroPumpList.contains(preferenceProvider.commonPumpSettings![i].deviceId),
                                  onChanged: (newValue){
                                    stateSetter(() {
                                      setState(() {
                                        if(selectedOroPumpList.contains(preferenceProvider.commonPumpSettings![i].deviceId)){
                                          selectedOroPumpList.remove(preferenceProvider.commonPumpSettings![i].deviceId);
                                        } else {
                                          selectedOroPumpList.add(preferenceProvider.commonPumpSettings![i].deviceId);
                                        }
                                      });
                                    });
                                  }
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                      },
                      child: const Text("CANCEL", style: TextStyle(color: Colors.red),),
                    ),
                    TextButton(
                      onPressed: selectedOroPumpList.isNotEmpty ? () async{
                        Navigator.of(context).pop();
                        await sendFunction();
                      } : null,
                      child: const Text("SEND"),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

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
    "900": "Calibration settings",
  };

  Future<void> sendFunction() async {
    final rtcError = validateAllRtcSettings();
    debugPrint("rtcError : $rtcError");
    if (rtcError != null) {
      _showRtcErrorDialog(rtcError);
      return;
    }
    // mqttPayloadProvider.preferencePayload = {};
    breakLoop = false;
    Map<String, dynamic> userData = {
      "userId": widget.customerId,
      "controllerId": widget.masterData['controllerId'],
      "createUser": widget.userId
    };

    Map<String, dynamic> payloadForSlave = {
      "400": {"401": onDelayTimer()}
    };

    final payload = shouldSendFailedPayloads ? getFailedPayload(isToGem: isToGem, sendAll: false) : getPayload(isToGem: isToGem, sendAll: false);
    final payloadParts = payload.split("?")[0].split(';');

    final payloadForGem = preferenceProvider.passwordValidationCode == 200
        ? getCalibrationPayload(isToGem: isToGem).split("?")[0].split(';')
        : payloadParts[0].isEmpty
        ? shouldSendFailedPayloads
        ? getFailedPayload(isToGem: isToGem, sendAll: true).split("?")[0].split(';')
        : getPayload(isToGem: isToGem, sendAll: true).split("?")[0].split(';')
        : payloadParts;
    try {
      bool isLevelSettingChanged = preferenceProvider.individualPumpSetting!.any((pump) => pump.settingList.any((setting) => AppConstants.levelSetting.contains(setting.type) && setting.changed));
      bool isAnyOtherChanged = preferenceProvider.commonPumpSettings!.any((pump) => pump.settingList.any((setting) => setting.changed));
      bool resultFromDialog = false;

      if(isToGem) {
        await validatePayloadSent(
            dialogContext: context,
            context: context,
            mqttPayloadProvider: mqttPayloadProvider,
            acknowledgedFunction: () async {
              setState(() {
                preferenceProvider.generalData!.controllerReadStatus = "1";
              });
            },
            payload: payloadForSlave,
            payloadCode: "400",
            deviceId: widget.masterData['deviceId']
        );
      }
      print('start sendFunction');
      /*print("isLevelSettingChanged :: $isLevelSettingChanged");
      print("isAnyOtherChanged :: $isAnyOtherChanged");
      print('isLevelSettingChanged && !isAnyOtherChanged :: ${isLevelSettingChanged && !isAnyOtherChanged}');*/
      if (preferenceProvider.commonPumpSettings!.isNotEmpty && !(isLevelSettingChanged && !isAnyOtherChanged)) {
        if((isToGem ? preferenceProvider.generalData!.controllerReadStatus == "1" : true) && payloadForGem.any((item) => item.trim().isNotEmpty)) {
          for (var i = 0; i < payloadForGem.length; i++) {
            var payloadToDecode = isToGem ? payloadForGem[i].split('+')[4] : payloadForGem[i];
            // print("payloadToDecode :: $payloadToDecode");
            var decodedData = jsonDecode(payloadToDecode);
            var key = decodedData.keys.first;
            int oroPumpIndex = 0;
            if(isToGem) {
              oroPumpIndex = preferenceProvider.commonPumpSettings!.indexWhere((element) => element.deviceId == payloadForGem[i].split('+')[2]);
            }
            setState(() {
              if(key.contains("100")) preferenceProvider.commonPumpSettings![oroPumpIndex].settingList[0].controllerReadStatus = "0";
              if(key.contains("200")) preferenceProvider.commonPumpSettings![oroPumpIndex].settingList[1].controllerReadStatus = "0";
              int pumpIndex = 0;
              for (var individualPump in preferenceProvider.individualPumpSetting ?? []) {
                if (preferenceProvider.commonPumpSettings![oroPumpIndex].deviceId == individualPump.deviceId) {
                  if(individualPump.output != null) {
                    pumpIndex = individualPump.output;
                  } else {
                    pumpIndex++;
                  }
                  for (var individualPumpSetting in individualPump.settingList) {
                    if (AppConstants.currentSetting.contains(individualPumpSetting.type)) {
                      if (key.contains("400-$pumpIndex")) {
                        individualPumpSetting.controllerReadStatus = "0";
                      }
                    } else if (AppConstants.timerSetting.contains(individualPumpSetting.type)) {
                      if (key.contains("300-$pumpIndex") || key.contains("500-$pumpIndex")) {
                        individualPumpSetting.controllerReadStatus = "0";
                      }
                    } else if (AppConstants.additionalSetting.contains(individualPumpSetting.type)) {
                      if (key.contains("600-$pumpIndex")) {
                        individualPumpSetting.controllerReadStatus = "0";
                      }
                    }

                  }
                }
              }
              if(preferenceProvider.passwordValidationCode == 200 && preferenceProvider.calibrationSetting!.isNotEmpty) {
                if(key.contains("900")) preferenceProvider.calibrationSetting![oroPumpIndex].settingList[1].controllerReadStatus = "0";
              }
            });
          }
          print('resultFromDialog');
          resultFromDialog = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return PayloadProgressDialog(
                payloads: preferenceProvider.passwordValidationCode == 200
                    ? getCalibrationPayload(isToGem: isToGem).split(';')
                    : payloadForGem,
                deviceId: widget.masterData['deviceId'],
                isToGem: isToGem,
                mqttService: mqttService,
                shouldSendFailedPayloads: shouldSendFailedPayloads,
                isWlc: isWlc,
              );
            },
          );
          if(getFailedPayload(sendAll: false, isToGem: isToGem).split(';').where((part) => part.isNotEmpty).toList().isEmpty) {
            preferenceProvider.generalData!.controllerReadStatus = "1";
            await Future.delayed(const Duration(milliseconds: 300));
          } else {
            preferenceProvider.generalData!.controllerReadStatus = "0";
          }
        }
      }

      await Future.delayed(Duration.zero, () {
        userData.addAll({
          'general': preferenceProvider.generalData!.toJson(),
          'contacts': [],
          'settings': preferenceProvider.individualPumpSetting?.map((item) => item.toJson()).toList(),
          'pumps': [],
          'calibrationSetting': preferenceProvider.calibrationSetting?.map((item) => item.toJson()).toList(),
          'commonPumps': preferenceProvider.commonPumpSettings?.map((item) => item.toJson()).toList(),
          'hardware': payloadForSlave,
          'changedPayload': generatePayloadMessageForChangedPayload(),
          'controllerReadStatus': preferenceProvider.generalData!.controllerReadStatus,
        });
      });
      await Future.delayed(Duration.zero, () async {
        final createUserPreference = await repository.createUserPreference(userData);
        final message = jsonDecode(createUserPreference.body);
        await showSnackBar(message: message['message']);
      });

    } catch (error, stackTrace) {
      showSnackBar(message: "Failed to update due to: $error");
      debugPrint("Error in preference sending: $error");
      debugPrint("Stack trace in preference sending: $stackTrace");
    }
  }

  Future<void> showSnackBar({required String message}) async{
    ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message:  message));
  }

  Map<String,dynamic> generatePayloadMessageForChangedPayload(){
    Map<String, dynamic> payload = {
      "commonPumpSettings" : {},
      "individualPumpSetting": {}
    };
    if(preferenceProvider.commonPumpSettings != null){
      for(var controller in preferenceProvider.commonPumpSettings!){
        for(var settingCategory in controller.settingList){
          for(var setting in settingCategory.setting){
            if(setting.isChanged){
              if(!payload["commonPumpSettings"].containsKey(controller.deviceId)){
                payload["commonPumpSettings"][controller.deviceId] = {};
              }
              if(!payload["commonPumpSettings"][controller.deviceId].containsKey(settingCategory.name)){
                payload["commonPumpSettings"][controller.deviceId][settingCategory.name] = {};
              }
              payload["commonPumpSettings"][controller.deviceId][settingCategory.name][setting.title] = setting.value.toString();
            }
          }
        }
      }
    }
    if(preferenceProvider.individualPumpSetting != null){
      for(var pump in preferenceProvider.individualPumpSetting!){
        for(var settingCategory in pump.settingList){
          for(var setting in settingCategory.setting){
            if(setting.isChanged){
              if(!payload["individualPumpSetting"].containsKey(pump.name)){
                payload["individualPumpSetting"][pump.name] = {};
              }
              if(!payload["individualPumpSetting"][pump.name].containsKey(settingCategory.name)){
                payload["individualPumpSetting"][pump.name][settingCategory.name] = {};
              }
              payload["individualPumpSetting"][pump.name][settingCategory.name][setting.title] = setting.value.toString();
            }
          }
        }
      }
    }
    return payload;
  }

  String onDelayTimer() {
    List<String> result = [];
    preferenceProvider.individualPumpSetting!.forEach((element) {
      String combinedResult = '${element.toGem()},${element.oDt()}';
      // String combinedResult = element.oDt();
      result.add(combinedResult);
    });

    return result.join(';');
  }

  String getPayload({required bool isToGem, required bool sendAll}) {
    List<String> result = [];
    for (var commonSetting in preferenceProvider.commonPumpSettings!) {
      List<String> temp = [];
      int oroPumpSerialNumber = commonSetting.serialNumber;
      String deviceId = commonSetting.deviceId;
      int categoryId = commonSetting.categoryId;
      int categoryId2 = 4;
      int interfaceType = commonSetting.interfaceTypeId;
      int referenceNumber = commonSetting.referenceNumber;
      int modelId = commonSetting.modelId;
      if(selectedOroPumpList.contains(deviceId)) {
        for (var settingCategory in commonSetting.settingList) {
          if (!sendAll ? (AppConstants.voltageSetting.contains(settingCategory.type) && settingCategory.changed) : AppConstants.voltageSetting.contains(settingCategory.type)) {
            final payload = jsonEncode({"200": jsonEncode({"sentSms": 'voltageconfig,${getSettingValue(settingCategory)}'})});
            temp.add(isToGem ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2": payload);
          } else if (!sendAll ? (AppConstants.otherSetting.contains(settingCategory.type) && settingCategory.changed) : AppConstants.otherSetting.contains(settingCategory.type)) {
            final payload = jsonEncode({"100": jsonEncode({"sentSms": 'ctconfig,${getSettingValue(settingCategory)}'})});
            temp.add(isToGem ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2": payload);
          }
        }

        /* if(isPumpWithValveModel && selectedSetting == 3 && isValveSetting) {
          for (var settingCategory in [preferenceProvider.valveSettings!]) {
            if ([211].contains(settingCategory.type)) {
              final payload = jsonEncode({"55": jsonEncode({"sentSms": '${preferenceProvider.mode == "Duration" ? 'valvesetting' : 'standalone'},${getSettingValue(settingCategory)}'})});
              temp.add(payload);
            }
          }
        }

        if(isPumpWithValveModel && selectedSetting == 3 && !isValveSetting) {
          for (var settingCategory in [preferenceProvider.moistureSettings!]) {
            if ([212].contains(settingCategory.type)) {
              final payload = jsonEncode({"57": jsonEncode({"sentSms": 'moisturesetting,${preferenceProvider.moistureSettings!.setting.map((e) => e.widgetTypeId != 2 ? e.value : e.value ? 1 : 0).toList().join(',')}'})});
              temp.add(payload);
            }
          }
        }*/

        int pumpIndex = 0;
        for(var individualPump in preferenceProvider.individualPumpSetting ?? []) {
          if ((isPumpWithValveModel || isPumpOnly || !isToGem) ? true : commonSetting.deviceId == individualPump.deviceId) {
            List<String> currentConfigList = [];
            List<String> delayConfigList = [];
            List<String> rtcConfigList = [];
            List<String> scheduleConfigList = [];
            if(individualPump.output != null) {
              pumpIndex = individualPump.output;
            } else {
              pumpIndex++;
            }
            for (var individualPumpSetting in individualPump.settingList) {
              final conditionToSend = (!sendAll ? individualPumpSetting.changed : true);
              if (AppConstants.currentSetting.contains(individualPumpSetting.type)) {
                if (conditionToSend) {
                  final payload = jsonEncode({
                    "400-$pumpIndex": jsonEncode({
                      "sentSms": 'currentconfig,$pumpIndex,${getSettingValue(individualPumpSetting)}'
                    })
                  });
                  currentConfigList.add(
                      isToGem
                          ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                          : payload
                  );
                }
              } else if (AppConstants.timerSetting.contains(individualPumpSetting.type)) {
                if (conditionToSend) {
                  final payload = jsonEncode({
                    "300-$pumpIndex": jsonEncode({
                      "sentSms": 'delayconfig,$pumpIndex,${getSettingValue(individualPumpSetting)}'
                    })
                  });
                  delayConfigList.add(
                      isToGem
                          ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                          : payload
                  );

                  final payload2 = jsonEncode({
                    "500-$pumpIndex": jsonEncode({
                      "sentSms": 'rtcconfig,$pumpIndex,${getRtcValue(individualPumpSetting)}'
                    })
                  });
                  rtcConfigList.add(
                      isToGem
                          ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload2+$categoryId2"
                          : payload2
                  );
                }
              } else if (AppConstants.additionalSetting.contains(individualPumpSetting.type)) {
                if (conditionToSend) {
                  int index = preferenceProvider.individualPumpSetting!
                      .indexWhere((e) => e.controllerId == commonSetting.controllerId);

                  final payload = jsonEncode({
                    "600-$pumpIndex": jsonEncode({
                      "sentSms":
                      'scheduleconfig,$pumpIndex,${getSettingValue(individualPumpSetting, controlToOroGem: (isPumpWithValveModel || !isToGem || isPumpOnly) ? false : preferenceProvider.individualPumpSetting![index].controlGem)}'
                    })
                  });

                  scheduleConfigList.add(
                      isToGem
                          ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                          : payload
                  );
                }
              }

            }

            if (currentConfigList.isNotEmpty) temp.add(currentConfigList.join('_'));
            if (delayConfigList.isNotEmpty) temp.add(delayConfigList.join('_'));
            if (rtcConfigList.isNotEmpty) temp.add(rtcConfigList.join('_'));
            if (scheduleConfigList.isNotEmpty) temp.add(scheduleConfigList.join('_'));
          }
        }
      }
      result.addAll(temp);
    }

    return result.join(';');
  }

  String getFailedPayload({required bool isToGem, required bool sendAll}) {

    List<String> result = [];
    for (var commonSetting in preferenceProvider.commonPumpSettings!) {
      List<String> temp = [];
      int oroPumpSerialNumber = commonSetting.serialNumber;
      String deviceId = commonSetting.deviceId;
      int categoryId = commonSetting.categoryId;
      int categoryId2 = 4;
      int interfaceType = commonSetting.interfaceTypeId;
      int referenceNumber = commonSetting.referenceNumber;
      int modelId = commonSetting.modelId;
      if(selectedOroPumpList.contains(deviceId)){
        for (var settingCategory in commonSetting.settingList) {
          if (!sendAll ? (AppConstants.voltageSetting.contains(settingCategory.type) && settingCategory.controllerReadStatus == "0") : AppConstants.voltageSetting.contains(settingCategory.type)) {
            final payload = jsonEncode({"200": jsonEncode({"sentSms": 'voltageconfig,${getSettingValue(settingCategory)}'})});
            temp.add(isToGem ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2": payload);
          } else if (!sendAll ? (AppConstants.otherSetting.contains(settingCategory.type) && settingCategory.controllerReadStatus == "0") : AppConstants.otherSetting.contains(settingCategory.type)) {
            final payload = jsonEncode({"100": jsonEncode({"sentSms": 'ctconfig,${getSettingValue(settingCategory)}'})});
            temp.add(isToGem ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2": payload);
          }
        }

        int pumpIndex = 0;
        for (var individualPump in preferenceProvider.individualPumpSetting ?? []) {
          if ((isPumpWithValveModel || !isToGem || isPumpOnly) ? true : commonSetting.deviceId == individualPump.deviceId) {          List<String> currentConfigList = [];
          List<String> delayConfigList = [];
          List<String> rtcConfigList = [];
          List<String> scheduleConfigList = [];
          if(individualPump.output != null) {
            pumpIndex = individualPump.output;
          } else {
            pumpIndex++;
          }
          for (var individualPumpSetting in individualPump.settingList) {
            final conditionToSend = (!sendAll ? individualPumpSetting.controllerReadStatus == "0" : true);
            if (AppConstants.currentSetting.contains(individualPumpSetting.type)) {
              if (conditionToSend) {
                final payload = jsonEncode({
                  "400-$pumpIndex": jsonEncode({
                    "sentSms": 'currentconfig,$pumpIndex,${getSettingValue(individualPumpSetting)}'
                  })
                });
                currentConfigList.add(
                  isToGem
                      ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                      : payload,
                );
              }
            } else if (AppConstants.timerSetting.contains(individualPumpSetting.type)) {
              if (conditionToSend) {
                final payload = jsonEncode({
                  "300-$pumpIndex": jsonEncode({
                    "sentSms": 'delayconfig,$pumpIndex,${getSettingValue(individualPumpSetting)}'
                  })
                });
                delayConfigList.add(
                  isToGem
                      ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                      : payload,
                );

                final payload2 = jsonEncode({
                  "500-$pumpIndex": jsonEncode({
                    "sentSms": 'rtcconfig,$pumpIndex,${getRtcValue(individualPumpSetting)}'
                  })
                });
                rtcConfigList.add(
                  isToGem
                      ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload2+$categoryId2"
                      : payload2,
                );
              }
            } else if (AppConstants.additionalSetting.contains(individualPumpSetting.type)) {
              if (conditionToSend) {
                int index = preferenceProvider.individualPumpSetting!
                    .indexWhere((e) => e.deviceId == commonSetting.deviceId);

                final payload = jsonEncode({
                  "600-$pumpIndex": jsonEncode({
                    "sentSms":
                    'scheduleconfig,$pumpIndex,${getSettingValue(individualPumpSetting, controlToOroGem: (isPumpWithValveModel || !isToGem || isPumpOnly) ? false : preferenceProvider.individualPumpSetting![index].controlGem)}'
                  })
                });

                scheduleConfigList.add(
                  isToGem
                      ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId2"
                      : payload,
                );
              }
            }

          }

          if (currentConfigList.isNotEmpty) temp.add(currentConfigList.join('_'));
          if (delayConfigList.isNotEmpty) temp.add(delayConfigList.join('_'));
          if (rtcConfigList.isNotEmpty) temp.add(rtcConfigList.join('_'));
          if (scheduleConfigList.isNotEmpty) temp.add(scheduleConfigList.join('_'));
          }
        }
      }
      result.addAll(temp);
    }

    return result.join(';');
  }

  String getCalibrationPayload({required bool isToGem}) {
    List result = [];
    for (var commonSetting in preferenceProvider.calibrationSetting!) {
      List temp = [];
      List temp2 = [];
      int oroPumpSerialNumber = commonSetting.serialNumber;
      String deviceId = commonSetting.deviceId;
      int categoryId = 4;
      int interfaceType = commonSetting.interfaceTypeId;
      int referenceNumber = commonSetting.referenceNumber;

      ///  This is doing for the aerator calibration payload position customization by (payload index)..
      CommonPumpSetting aeratorCalibrationSetting = CommonPumpSetting(
          controllerId: commonSetting.controllerId,
          categoryId: commonSetting.categoryId,
          modelId: commonSetting.modelId,
          deviceId: commonSetting.deviceId,
          deviceName: commonSetting.deviceName,
          serialNumber: commonSetting.serialNumber,
          referenceNumber: commonSetting.referenceNumber,
          interfaceTypeId: commonSetting.interfaceTypeId,
          settingList: [
            SettingList(
                type: 608,
                changed: true,
                controllerReadStatus: '0',
                name: 'Aerator',
                setting: [
                  for(var i in commonSetting.settingList)
                    ...i.setting
                ]
            )
          ]
      );
      List<SettingList> aeratorOrNormal = AppConstants.aquacultureModelList.contains(widget.masterData['modelId'])
          ? aeratorCalibrationSetting.settingList : commonSetting.settingList;
      if(selectedOroPumpList.contains(deviceId)) {
        for (var settingCategory in aeratorOrNormal) {
          if (AppConstants.voltageCalibration.contains(settingCategory.type)) {
            final payload = jsonEncode({
              "900": jsonEncode({"sentSms": 'calibration,${getSettingValue(settingCategory)}'})
            });
            temp.add(isToGem
                ? "$oroPumpSerialNumber+$referenceNumber+$deviceId+$interfaceType+$payload+$categoryId"
                : payload);
          } else if (AppConstants.currentCalibration.contains(settingCategory.type)) {
            var splitParts = [];
            if(isToGem) {
              splitParts = temp[0].split('+');
            }
            var tempMap = jsonDecode(jsonDecode(isToGem ? splitParts[4] : temp[0])['900']);
            temp2 = tempMap['sentSms'].toString().split(',');
            temp2.add('${getSettingValue(settingCategory)}');
            tempMap['sentSms'] = temp2.join(',');
            debugPrint("tempMap : $tempMap");
            if(isToGem) {
              splitParts[4] = jsonEncode({"900": jsonEncode(tempMap)});
              temp[0] = splitParts.join('+');
            } else {
              temp[0] = jsonEncode({"900": jsonEncode(tempMap)});
            }
          } else if (AppConstants.otherCalibration.contains(settingCategory.type)) {
            var splitParts = [];
            if(isToGem) {
              splitParts = temp[0].split('+');
            }
            var tempMap = jsonDecode(jsonDecode(isToGem ? splitParts[4] : temp[0])['900']);
            temp2 = tempMap['sentSms'].toString().split(',');
            temp2.add('${getSettingValue(settingCategory)}');
            tempMap['sentSms'] = temp2.join(',');
            if(isToGem) {
              splitParts[4] = jsonEncode({"900": jsonEncode(tempMap)});
              temp[0] = splitParts.join('+');
            } else {
              temp[0] = jsonEncode({"900": jsonEncode(tempMap)});
            }
          }
        }
      }
      result.addAll(temp);
    }
    return result.join(';');
  }

  String getRtcValue(settingCategory) {
    List listToAdd = [];
    settingCategory.setting.forEach((setting) {
      String? value;
      if(setting.title.toUpperCase() == "RTC") {
        listToAdd.add(setting.value ? 1 : 0);
      }
      if(setting.title.toUpperCase() == "RTC TIMER") {
        List<String> rtcTimes = [];

        for(var i = 0; i < setting.rtcSettings!.length; i++){
          final onTime = setting.rtcSettings![i].onTime;
          final offTime = setting.rtcSettings![i].offTime;
          rtcTimes.add('${onTime.replaceAll(":", ",")},${offTime.replaceAll(":", ",")}');
        }
        value = rtcTimes.join(',');
      }
      if(value != null) {
        listToAdd.add(value);
      }
    });
    return listToAdd.join(",");
  }

  dynamic getSettingValue(settingCategory, {bool? controlToOroGem}) {
    debugPrint('settingCategory.name ::: ${settingCategory.name}');
    List<String> values = [];
    List<WidgetSetting> filterList = List<WidgetSetting>.from(settingCategory.setting)
      ..sort((a, b) => a.payloadIndex.compareTo(b.payloadIndex));
    for (var setting in filterList) {
      String? value;
      if (setting.value is bool) {
        if(setting.title.toUpperCase() != 'RTC') {
          if(settingCategory.type == 211) {
            if(preferenceProvider.mode == "Duration" && setting.serialNumber != 5) {
              value = setting.value ? "1" : "0";
            } else if(preferenceProvider.mode == "Manual" && setting.serialNumber == 5){
              value = setting.value ? "1" : "0";
            }
          } else {
            value = setting.value ? "1" : "0";
          }
        }
        if(controlToOroGem ?? false) {
          if(setting.title.toUpperCase() == "TANK ON/OFF" || setting.title.toUpperCase() == "SUMP ON/OFF") {
            value = '0';
          }
        }
      } else if (setting.value is String) {
        if(settingCategory.type == 211) {
          if(setting.value.toString().contains(',')) {
            final parts = setting.value.split(',');
            if(setting.serialNumber <= 15) {
              if(preferenceProvider.mode == "Manual" && setting.serialNumber > 5) {
                value = "${parts[1]}";
              } else {
                final result = parts[0].split(':');
                value = "${result[0]},${result[1]}";
              }
            } else {
              value = setting.value;
            }
          } else {
            if(preferenceProvider.mode != "Manual") {
              if(setting.value.toString().contains(':')) {
                value = setting.value.replaceAll(":", ",");
              } else {
                value = setting.value;
              }
            }
          }
        } else {
          switch (setting.widgetTypeId) {
            case 3:
              if(setting.title.toUpperCase().contains("LIGHT")) {
                final result = setting.value.toString().split(':');
                value = setting.value.isEmpty ? "00,00" : "${result[0]},${result[1]}";
              } else {
                value = setting.value.isEmpty ? "00,00,00" : setting.value.replaceAll(":", ",");
              }
              break;
            case 1:
              if(settingCategory.type == 211 && preferenceProvider.mode != "Manual") {
                value = setting.value.isEmpty ? "000" : setting.value;
              } else {
                value = setting.value.isEmpty ? "000" : setting.value;
              }
              break;
            case 2:
              final parts = setting.value.split(',');
              final result = parts[0].split(':');
              value = "${result[0]},${result[1]}";
            default:
              value = setting.value.isEmpty ? "0" : setting.value;
              break;
          }
        }
      } else {
        if (setting.title.toUpperCase() == '2 PHASE'
            || setting.title.toUpperCase() == 'AUTO RESTART 2 PHASE'
            || (setting.title.toUpperCase() == "AUTO RESTART" && setting.serialNumber == 8)
            || setting.title.toUpperCase() == 'UPPER TANK LINEAR LEVEL SENSOR'
            || setting.title.toUpperCase() == 'LOWER TANK LINEAR LEVEL SENSOR'
        ) {
          const phaseMap = {
            '[false, false, false]': '0',
            '[false, false, true]': '4',
            '[false, true, false]': '2',
            '[false, true, true]': '6',
            '[true, false, false]': '1',
            '[true, false, true]': '5',
            '[true, true, false]': '3',
            '[true, true, true]': '7',
          };
          value = phaseMap[setting.value.toString()] ?? "0";
        }
      }
      if (value != null) values.add(value);
    }
    print("values => $values");
    return values.join(",");
  }

/*  Future<void> processPayloads({
    required BuildContext context,
    required List<String> payload,
    required bool isToGem,
    required MqttService mqttService,
    required String deviceId,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PayloadProgressDialog(
          payloads: payload,
          deviceId: deviceId,
          isToGem: isToGem,
          mqttService: mqttService,
          shouldSendFailedPayloads: shouldSendFailedPayloads,
        );
      },
    );
  }*/
}

Widget buildCustomListTileWidget({
  required int modelId,
  required BuildContext context,
  required String title,
  String? subTitle,
  bool showTrailing = true,
  required int widgetType,
  dynamic value,
  void Function(dynamic newValue)? onValueChange,
  required Widget leading,
  bool conditionToShow = true,
  required bool hidden,
  required bool display,
  bool enabled = true,
  required List<TextInputFormatter> inputFormatters,
  required List<String> dataList
}) {
  debugPrint("$title == $widgetType ");
  Widget customWidget;
  switch(widgetType) {
    case 1:case 4:
    customWidget = SizedBox(
      width: 80,
      child: TextFormField(
        key: Key(title),
        enabled: enabled,
        initialValue: value is String ? value : "",
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: (widgetType == 1 && AppConstants.gemModelList.contains(modelId)) ? AppProperties.regexForNumbers : AppProperties.regexForDecimal,
        decoration: const InputDecoration(
          hintText: "000",
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            borderSide: BorderSide.none,
          ),
          fillColor: cardColor,
          filled: true,
          // errorText: errorText
        ),
        onTapOutside: (_) {
          FocusScope.of(context).unfocus();
        },
        onChanged: (newValue) {
          onValueChange?.call(newValue);
        },
      ),
    );
    break;
    case 2:
      customWidget = Switch(
        value: enabled ? (value != "" ? value : false) ?? false : false,
        onChanged: (newValue) {
          if(enabled) onValueChange?.call(newValue);
        },
      );
      break;
    case 3:
      customWidget = enabled ? CustomNativeTimePicker(
        initialValue: value is String ? value : "00:00:00",
        is24HourMode: true,
        onChanged: (newValue) {
          enabled ? onValueChange?.call(newValue) : null;
        }, modelId: 1,
      ) : Text(value, overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 14),
      );
      break;
    case 6:
      customWidget = SizedBox(
        width: 80,
        child: Text(
          value ?? "Wait",
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 14),
        ),
      );
      break;
    case 7:
      customWidget = SizedBox(
        width: 80,
        child: buildPopUpMenuButton(context: context, dataList: dataList, onSelected: (newValue) {
          if(enabled) onValueChange?.call(newValue);
        }, child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(5)),
          child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16),),)),
      );
      break;
    default:
      customWidget = Text('Unsupported Widget Type: $widgetType');
      break;
  }
  if(display == false){
    return Container();
  }
  return Visibility(
    visible: !hidden,
    child: CustomAnimatedSwitcher(
      condition: conditionToShow,
      child: ListTile(
        contentPadding: subTitle != null ? const EdgeInsets.symmetric(horizontal: 10) : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        horizontalTitleGap: 20,
        leading: IntrinsicWidth(child: leading),
        title: Text(title),
        subtitle: subTitle != null ? Text(subTitle) : null,
        trailing: showTrailing ? IntrinsicWidth(child: customWidget) : null,
      ),
    ),
  );
}