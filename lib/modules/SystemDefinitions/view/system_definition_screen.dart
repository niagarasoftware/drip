import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Constants/properties.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:provider/provider.dart';
import '../model/system_definition_model.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../StateManagement/overall_use.dart';
import '../../IrrigationProgram/widgets/custom_tile.dart';
import '../repository/system_definitions_repo.dart';
import '../state_management/system_definition_provider.dart';
import '../../IrrigationProgram/widgets/custom_animated_switcher.dart';
import '../../IrrigationProgram/widgets/custom_native_time_picker.dart';
import '../widgets/custom_snack_bar.dart';
import '../../../services/http_service.dart';
import '../../../utils/environment.dart';
import '../../IrrigationProgram/view/program_library.dart';
import '../../IrrigationProgram/view/schedule_screen.dart';

import '../widgets/custom_switch_tile.dart';
import '../widgets/custom_timer_tile.dart';

class SystemDefinition extends StatefulWidget {
  final int userId;
  final int controllerId;
  final int customerId;
  final String deviceId;
  const SystemDefinition({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.deviceId,
    required this.customerId,
  });

  @override
  State<SystemDefinition> createState() => _SystemDefinitionState();
}

class _SystemDefinitionState extends State<SystemDefinition> {
  final SystemDefinitionsRepository repository = SystemDefinitionsRepository(HttpService());
  late OverAllUse overAllPvd;
  late SystemDefinitionProvider systemDefinitionProvider;
  late MqttPayloadProvider mqttPayloadProvider;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    systemDefinitionProvider = Provider.of<SystemDefinitionProvider>(context, listen: false);
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
    overAllPvd = Provider.of<OverAllUse>(context, listen: false);
    if(mounted){
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        systemDefinitionProvider.getUserPlanningSystemDefinition(widget.customerId, widget.controllerId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    systemDefinitionProvider = Provider.of<SystemDefinitionProvider>(context, listen: true);
    mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: true);
    overAllPvd = Provider.of<OverAllUse>(context, listen: true);
    final screenSize = MediaQuery.of(context).size.width;
    return systemDefinitionProvider.irrigationLineSystemData != null ? RefreshIndicator(
      onRefresh: () => systemDefinitionProvider.getUserPlanningSystemDefinition(widget.customerId, widget.controllerId),
      child: Scaffold(
        appBar: screenSize <= 600
            ? AppBar(
          title: const Text("System Definition"),
          automaticallyImplyLeading: true,
          bottom: PreferredSize(
              preferredSize: const Size(double.maxFinite, 35),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for(var i = 0; i < systemDefinitionProvider.irrigationLineSystemData!.length; i++)
                      AppProperties.buildSideBarMenuList(
                        context: context,
                        title: systemDefinitionProvider.irrigationLineSystemData![i].name,
                        dataList: systemDefinitionProvider.irrigationLineSystemData!.map((e) => e.name).toList(),
                        index: i,
                        selected: systemDefinitionProvider.selectedIrrigationLine == i,
                        onTap: (index) {
                          systemDefinitionProvider.updateSelectedProgramCategory(index);
                        },
                      ),
                  ],
                ),
              )
          ),
        )
            : PreferredSize(preferredSize: Size.zero, child: Container()),
        body: (systemDefinitionProvider.irrigationLineSystemData != null)
            ? LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              children: [
                if(screenSize >= 600)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints){
                        return Row(
                          children: [
                            for(var i = 0; i < systemDefinitionProvider.irrigationLineSystemData!.length; i++)
                              SizedBox(
                                width: 200,
                                child: AppProperties.buildSideBarMenuList(
                                  context: context,
                                  title: systemDefinitionProvider.irrigationLineSystemData![i].name,
                                  dataList: systemDefinitionProvider.irrigationLineSystemData!.map((e) => e.name).toList(),
                                  index: i,
                                  selected: systemDefinitionProvider.selectedIrrigationLine == i,
                                  onTap: (index) {
                                    systemDefinitionProvider.updateSelectedProgramCategory(index);
                                  }, constraints: constraints,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    // padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: systemDefinitionProvider.irrigationLineSystemData!.length,
                      itemBuilder: (BuildContext context, int lineIndex) {
                        if(systemDefinitionProvider.selectedIrrigationLine == lineIndex) {
                          return screenSize <= 600 ? Column(
                            children: [
                              if(systemDefinitionProvider.selectedIrrigationLine == 0)
                                const SizedBox(height: 15,),
                              if(systemDefinitionProvider.selectedIrrigationLine == 0)
                                buildSwitchTile(
                                  title: "All irrigation line should run while power off",
                                  value: systemDefinitionProvider.enableAll,
                                  onChanged: (newValue) {
                                    setState(() {
                                      systemDefinitionProvider.enableAll = newValue;
                                      for(var i = 0; i < systemDefinitionProvider.irrigationLineSystemData!.length; i++) {
                                        if(systemDefinitionProvider.enableAll) {
                                          systemDefinitionProvider.irrigationLineSystemData![i].systemDefinition.irrigationLineOn = true;
                                        } else {
                                          systemDefinitionProvider.irrigationLineSystemData![i].systemDefinition.irrigationLineOn = false;
                                        }
                                      }
                                    });
                                  },
                                  icon: Icons.clear_all,
                                ),
                              const SizedBox(height: 15,),
                              buildSwitchTile(
                                title: "Should run while power off",
                                value: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.irrigationLineOn,
                                onChanged: (newValue) {
                                  setState(() {
                                    systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.irrigationLineOn = newValue;
                                    if(systemDefinitionProvider.irrigationLineSystemData!.every((element) => element.systemDefinition.irrigationLineOn == true)){
                                      systemDefinitionProvider.enableAll = true;
                                    } else {
                                      systemDefinitionProvider.enableAll = false;
                                    }
                                  });
                                },
                                icon: Icons.power_settings_new,
                              ),
                              const SizedBox(height: 15,),
                              buildSwitchTile(
                                title: "Enable energy save function",
                                value: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.status,
                                onChanged: (newValue) {
                                  setState(() {
                                    systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.status = newValue;
                                  });
                                },
                                icon: Icons.energy_savings_leaf,
                              ),
                              const SizedBox(height: 10,),
                              if (systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.status)
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: buildScheduleItem(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          context: context,
                                          title: 'Start day time',
                                          iconColor: Colors.green,
                                          backGroundColor: cardColor,
                                          icon: Icons.start,
                                          color: Colors.white,
                                          child: CustomNativeTimePicker(
                                              initialValue: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.startDayTime,
                                              is24HourMode: false,
                                              onChanged: (newValue){
                                                setState(() {
                                                  systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.startDayTime = newValue;
                                                });
                                              }, modelId: 1,),
                                        ),
                                      ),
                                      Expanded(
                                        child: buildScheduleItem(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          context: context,
                                          title: 'Stop day time',
                                          iconColor: Colors.red.withValues(alpha: 0.7),
                                          backGroundColor: cardColor,
                                          color: Colors.white,
                                          icon: Icons.stop,
                                          child: CustomNativeTimePicker(
                                              initialValue: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.stopDayTime,
                                              is24HourMode: false,
                                              onChanged: (newValue){
                                                setState(() {
                                                  systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.stopDayTime = newValue;
                                                });
                                              }, modelId: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 10,),
                              buildSwitchTile(
                                title: "Pause by days",
                                value: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.pauseMainLine,
                                onChanged: (newValue) {
                                  setState(() {
                                    systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.pauseMainLine = newValue;
                                  });
                                },
                                icon: Icons.pause,
                              ),
                              const SizedBox(height: 15,),
                              if (systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.pauseMainLine)
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 15),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                      boxShadow: AppProperties.customBoxShadowLiteTheme
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            gradient: AppProperties.linearGradientLeading,
                                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text("S.No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Expanded(child: Text("Days", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),)),
                                            Expanded(child: Text("From", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            Expanded(child: Text("To", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center,)),
                                            Expanded(child: Text("Yes/No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
                                          ],
                                        ),
                                      ),
                                      for(var i = 0; i < 7; i++)
                                        buildDayTimePicker(
                                            day: systemDefinitionProvider.days[i],
                                            dayTimeRange: systemDefinitionProvider.daysFromAndToTimes(lineIndex: lineIndex)[i],
                                            dayCount: systemDefinitionProvider.values[i],
                                            checkBoxValue: systemDefinitionProvider.isSelectedList(lineIndex: lineIndex)[i],
                                            constraints: constraints,
                                            lineIndex: lineIndex
                                        )
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 80,),
                            ],
                          ) : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8)
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      Container(
                                          padding: const EdgeInsets.all(8),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8)
                                          ),
                                          child: Row(
                                            children: [
                                              Text(systemDefinitionProvider.irrigationLineSystemData![lineIndex].name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),),
                                            ],
                                          )
                                      ),
                                      const SizedBox(height: 20,),
                                      if(systemDefinitionProvider.selectedIrrigationLine == 0)
                                        Row(
                                          children: [
                                            SizedBox(width: constraints.maxWidth * 0.02,),
                                            Checkbox(
                                                value: systemDefinitionProvider.enableAll,
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    systemDefinitionProvider.enableAll = newValue!;
                                                    for(var i = 0; i < systemDefinitionProvider.irrigationLineSystemData!.length; i++) {
                                                      if(systemDefinitionProvider.enableAll) {
                                                        systemDefinitionProvider.irrigationLineSystemData![i].systemDefinition.irrigationLineOn = true;
                                                      } else {
                                                        systemDefinitionProvider.irrigationLineSystemData![i].systemDefinition.irrigationLineOn = false;
                                                      }
                                                    }
                                                  });
                                                }
                                            ),
                                            SizedBox(width: constraints.maxWidth * 0.02,),
                                            const Text("All irrigation line should run while power off"),
                                          ],
                                        ),
                                      const SizedBox(height: 20,),
                                      Row(
                                        children: [
                                          SizedBox(width: constraints.maxWidth * 0.02,),
                                          Checkbox(
                                              value: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.irrigationLineOn,
                                              onChanged: (newValue) {
                                                setState(() {
                                                  systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.irrigationLineOn = newValue!;
                                                  if(systemDefinitionProvider.irrigationLineSystemData!.every((element) => element.systemDefinition.irrigationLineOn == true)){
                                                    systemDefinitionProvider.enableAll = true;
                                                  } else {
                                                    systemDefinitionProvider.enableAll = false;
                                                  }
                                                });
                                              }
                                          ),
                                          SizedBox(width: constraints.maxWidth * 0.02,),
                                          const Text("Should run while power off"),
                                        ],
                                      ),
                                      const SizedBox(height: 20,),
                                      Row(
                                        children: [
                                          SizedBox(width: constraints.maxWidth * 0.02,),
                                          Checkbox(
                                              value: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.status,
                                              onChanged: (newValue) {
                                                setState(() {
                                                  systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.status = newValue!;
                                                });
                                              }
                                          ),
                                          SizedBox(width: constraints.maxWidth * 0.02,),
                                          const Text("Energy save function"),
                                        ],
                                      ),
                                      const SizedBox(height: 20,),
                                      CustomAnimatedSwitcher(
                                        condition: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.status,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            SizedBox(width: constraints.maxWidth * 0.02,),
                                            SizedBox(width: constraints.maxWidth * 0.02,),
                                            SizedBox(width: constraints.maxWidth * 0.02,),
                                            const Text("Start day time"),
                                            SizedBox(width: constraints.maxWidth * 0.05,),
                                            buildTimePicker(
                                                currentValue: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.startDayTime,
                                                onTap: (newValue) {
                                                  setState(() {
                                                    systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.startDayTime = newValue;
                                                  });
                                                },
                                                is24HourMode: false
                                            ),
                                            SizedBox(width: constraints.maxWidth * 0.05),
                                            const Text("End day time"),
                                            SizedBox(width: constraints.maxWidth * 0.05,),
                                            buildTimePicker(
                                                currentValue: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.stopDayTime,
                                                onTap: (newValue) {
                                                  setState(() {
                                                    systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.stopDayTime = newValue;
                                                  });
                                                },
                                                is24HourMode: false
                                            ),
                                          ],
                                        ),),
                                      const SizedBox(height: 20,),
                                      CustomAnimatedSwitcher(condition: true, child: Row(
                                        children: [
                                          SizedBox(width: constraints.maxWidth * 0.02,),
                                          Checkbox(
                                              value: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.pauseMainLine,
                                              onChanged: (newValue) {
                                                setState(() {
                                                  systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.pauseMainLine = newValue!;
                                                });
                                              }
                                          ),
                                          SizedBox(width: constraints.maxWidth * 0.02,),
                                          const Text("Pause by days"),
                                        ],
                                      )),
                                      const SizedBox(height: 20,),
                                      CustomAnimatedSwitcher(
                                          condition: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.pauseMainLine,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Column(
                                                children: [
                                                  Text("Days", style: Theme.of(context).textTheme.bodyLarge,),
                                                  const SizedBox(height: 10,),
                                                  Text("From", style: Theme.of(context).textTheme.bodyLarge),
                                                  const SizedBox(height: 10,),
                                                  Text("To", style: Theme.of(context).textTheme.bodyLarge),
                                                ],
                                              ),
                                              for(var i = 0; i < 7; i++)
                                                buildDayTimePicker(
                                                    day: systemDefinitionProvider.days[i],
                                                    dayTimeRange: systemDefinitionProvider.daysFromAndToTimes(lineIndex: lineIndex)[i],
                                                    dayCount: systemDefinitionProvider.values[i],
                                                    checkBoxValue: systemDefinitionProvider.isSelectedList(lineIndex: lineIndex)[i],
                                                    constraints: constraints,
                                                    lineIndex: lineIndex
                                                )
                                            ],
                                          ))
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10,),
                                // Container(
                                //   decoration: BoxDecoration(
                                //       color: Colors.white,
                                //       borderRadius: BorderRadius.circular(8)
                                //   ),
                                //   padding: const EdgeInsets.all(10),
                                //   child: Column(
                                //     children: [
                                //       Container(
                                //           padding: const EdgeInsets.all(8),
                                //           width: double.infinity,
                                //           decoration: BoxDecoration(
                                //               color: Theme.of(context).primaryColor.withOpacity(0.2),
                                //               borderRadius: BorderRadius.circular(8)
                                //           ),
                                //           child: Text("Power off recovery ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),)
                                //       ),
                                //       const SizedBox(height: 20,),
                                //       Row(
                                //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //         children: [
                                //           Row(
                                //             children: [
                                //               SizedBox(width: constraints.maxWidth * 0.02,),
                                //               const Text("When the power is out for longer than"),
                                //               SizedBox(width: constraints.maxWidth * 0.02,),
                                //               buildTimePicker(systemDefinitionProvider.powerOffRecoveryModel!.duration, (newValue) {
                                //                 systemDefinitionProvider.updateValues(newValue, "duration");
                                //               }, true),
                                //             ],
                                //           ),
                                //           Row(
                                //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                //             children: List.generate(systemDefinitionProvider.options.length, (index) {
                                //               return Row(
                                //                 children: [
                                //                   Checkbox(
                                //                     value: systemDefinitionProvider.powerOffRecoveryModel!.selectedOption.contains(systemDefinitionProvider.options[index])
                                //                         ? true : false,
                                //                     onChanged: (newValue) {
                                //                       systemDefinitionProvider.updateCheckBoxesForOption(newValue, systemDefinitionProvider.options[index], index);
                                //                     },
                                //                   ),
                                //                   Text(systemDefinitionProvider.options[index]),
                                //                   const SizedBox(width: 20,)
                                //                 ],
                                //               );
                                //             }).toList(),
                                //           ),
                                //         ],
                                //       )
                                //     ],
                                //   ),
                                // )
                              ],
                            ),
                          );
                        }
                        return Container();
                      }
                  ),
                )
              ],
            );
          },
        )
            : const Center(child: CircularProgressIndicator()),
        floatingActionButton: MaterialButton(
          minWidth: 100,
          color: systemDefinitionProvider.controllerReadStatus == "1" ? Theme.of(context).primaryColor : Colors.orangeAccent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          textColor: systemDefinitionProvider.controllerReadStatus == "1" ? Colors.white : Colors.black,
          onPressed: () async{
            // print(systemDefinitionProvider.irrigationLineSystemData!.map((e) => e.toMqtt()).toList().join("\n"));
            Map<String, dynamic> dataToMqtt = {
              "2200": {
                "2201": systemDefinitionProvider.irrigationLineSystemData!.map((e) => e.toMqtt()).toList().join(";"),
              }
            };

            Map<String, dynamic> userData = {
              "userId": widget.customerId,
              "controllerId": widget.controllerId,
              "createUser": widget.userId ,
              "systemDefinition" : {
                "systemDefinition" : systemDefinitionProvider.irrigationLineSystemData!.map((e) => e.toJson()).toList(),
                "controllerReadStatus" : "1"
              },
              "hardware": dataToMqtt
            };
            // print(dataToMqtt);
            try {
              await validatePayloadSent(
                  dialogContext: context,
                  context: context,
                  mqttPayloadProvider: mqttPayloadProvider,
                  acknowledgedFunction: () {
                    setState(() {
                      userData['systemDefinition']['controllerReadStatus'] = "1";
                      systemDefinitionProvider.controllerReadStatus = "1";
                      // userData['controllerReadStatus'] = "1";
                      // if(userData['controllerReadStatus'] == "0") {
                      //   userData['hardware'] = {};
                      // }
                    });
                    // showSnackBar(message: "${mqttPayloadProvider.messageFromHw['Name']} from controller", context: context);
                  },
                  payload: dataToMqtt,
                  payloadCode: "2200",
                  deviceId: widget.deviceId
              );
              await Future.delayed(const Duration(seconds: 1), () async {
                final createUserPlanningSystemDefinition = await repository.createUserPlanningSystemDefinition(userData);
                 final response = jsonDecode(createUserPlanningSystemDefinition.body);
                print('response:$response');
                if(createUserPlanningSystemDefinition.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: response['message']));
                }
              });
              MqttService().topicToPublishAndItsMessage(jsonEncode(dataToMqtt), '${Environment.mqttPublishTopic}/${widget.deviceId}');
              // showNavigationDialog(context: context, menuId: widget.menuId, ack: systemDefinitionProvider.controllerReadStatus == "1");
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(message: 'Failed to update because of $error'));
              debugPrint("Error: $error");
            }
          },
          child: const Text("Send"),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    ) : const Center(child: CircularProgressIndicator());
  }

  Widget buildTimePicker(
      {required String currentValue, required Function(String) onTap, required bool is24HourMode}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.black54),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomNativeTimePicker(
          initialValue: currentValue,
          is24HourMode: is24HourMode,
          onChanged: (newTime ) => onTap(newTime), modelId: 1,
      ),
    );
  }

  Widget buildSwitchTile(
      {required String title, required bool value, required Function(bool) onChanged, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          boxShadow: AppProperties.customBoxShadowLiteTheme
      ),
      child: CustomSwitchTile(
        title: title,
        showCircleAvatar: true,
        value: value,
        icon: icon,
        onChanged: onChanged,
      ),
    );
  }

  Widget buildTimerTile(
      {required String subtitle,
        required String initialValue,
        required Function(String) onChanged,
        required IconData icon,
        required bool is24HourMode}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: AppProperties.customBoxShadowLiteTheme
      ),
      child: CustomTimerTile(
        subtitle: subtitle,
        initialValue: initialValue,
        onChanged: onChanged,
        isSeconds: false,
        icon: icon,
        isNative: true,
        is24HourMode: is24HourMode, modelId: 1,
      ),
    );
  }

  Widget buildDayTimePicker(
      {required String day,
        required DayTimeRange dayTimeRange,
        required dayCount,
        required checkBoxValue,
        required int lineIndex,
        required constraints}) {
    return Consumer<SystemDefinitionProvider>(builder: (BuildContext context, SystemDefinitionProvider systemDefinitionProvider, child) {
      return constraints.maxWidth <= 600 ?
      CustomTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: day,
        trailing: SizedBox(
          width: constraints.maxWidth <= 600 ? constraints.maxWidth * 0.55 : constraints.maxWidth * 0.25,
          child: buildTimeRow(
              from: dayTimeRange.from,
              to: dayTimeRange.to,
              onChanged: (newFrom, newTo) => systemDefinitionProvider.updateDayTimeRange(dayTimeRange, newFrom, newTo),
              checkBox: checkBoxValue,
              onChangedBool: (newValue) => systemDefinitionProvider.updateCheckBoxes(dayCount, newValue, lineIndex),
              constraints: constraints
          ),
        ),
        content: dayCount,
      ) :
      Column(
        children: [
          Row(
            children: [
              Text(day, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),),
              Checkbox(value: checkBoxValue, onChanged: (newValue) => systemDefinitionProvider.updateCheckBoxes(dayCount, newValue, lineIndex))
            ],
          ),
          buildTimeRow(
              from: dayTimeRange.from,
              to: dayTimeRange.to,
              onChanged: (newFrom, newTo) => systemDefinitionProvider.updateDayTimeRange(dayTimeRange, newFrom, newTo),
              checkBox: checkBoxValue,
              onChangedBool: (newValue) => systemDefinitionProvider.updateCheckBoxes(dayCount, newValue, lineIndex),
              constraints: constraints
          )
        ],
      );
    });
  }

  Widget buildTimeRow(
      {required String from,
        required String to,
        required Function(String, String) onChanged,
        required bool checkBox,
        required Function(bool?) onChangedBool,
        required constraints}) {
    return constraints.maxWidth <= 600 ?
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IgnorePointer(
          ignoring: !checkBox,
          child: CustomNativeTimePicker(
              initialValue: from, style: TextStyle(color: checkBox ? Colors.black : Colors.grey, fontSize: 16),
              is24HourMode: false,
              onChanged: (newTime ) => onChanged(newTime, to), modelId: 1,
          ),
        ),
        IgnorePointer(
          ignoring: !checkBox,
          child: CustomNativeTimePicker(
              initialValue: to, style: TextStyle(color: checkBox ? Colors.black : Colors.grey, fontSize: 16),
              is24HourMode: false,
              onChanged: (newTime ) => onChanged(from, newTime), modelId: 1,
          ),
        ),
        Checkbox(value: checkBox, onChanged: onChangedBool),
      ],
    ) :
    Column(
      children: [
        const SizedBox(height: 10,),
        IgnorePointer(
          ignoring: !checkBox,
          child: CustomNativeTimePicker(
              initialValue: from, style: TextStyle(color: checkBox ? Colors.black : Colors.grey, fontSize: 16),
              is24HourMode: false,
              onChanged: (newTime ) => onChanged(newTime, to), modelId: 1,
          ),
        ),
        const SizedBox(height: 10,),
        IgnorePointer(
          ignoring: !checkBox,
          child: CustomNativeTimePicker(
              initialValue: to, style: TextStyle(color: checkBox ? Colors.black : Colors.grey, fontSize: 16),
              is24HourMode: false,
              onChanged: (newTime ) => onChanged(from, newTime), modelId: 1,
          ),
        )
      ],
    );
  }
}

// if (systemDefinitionProvider.selectedSegment == 0) {
//   return Column(
//     children: [
//       const SizedBox(height: 15,),
//       buildSwitchTile(
//         title: "Enable energy save function",
//         value: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.status,
//         onChanged: (newValue) {
//           setState(() {
//             systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.status = newValue;
//           });
//           print(newValue);
//           print(systemDefinitionProvider.selectedSegment);
//         },
//         icon: Icons.energy_savings_leaf,
//       ),
//       const SizedBox(height: 10,),
//       if (systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.status)
//         Container(
//           margin: const EdgeInsets.symmetric(horizontal: 15),
//           child: Row(
//             children: [
//               Expanded(
//                 child: buildScheduleItem(
//                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//                   context: context,
//                   title: 'Start day time',
//                   iconColor: Colors.green,
//                   backGroundColor: cardColor,
//                   icon: Icons.start,
//                   color: Colors.white,
//                   child: CustomNativeTimePicker(
//                       initialValue: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.startDayTime,
//                       is24HourMode: false,
//                       onChanged: (newValue){
//                         setState(() {
//                           systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.startDayTime = newValue;
//                         });
//                       }),
//                 ),
//               ),
//               Expanded(
//                 child: buildScheduleItem(
//                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//                   context: context,
//                   title: 'Stop day time',
//                   iconColor: Colors.red.withOpacity(0.7),
//                   backGroundColor: cardColor,
//                   color: Colors.white,
//                   icon: Icons.stop,
//                   child: CustomNativeTimePicker(
//                       initialValue: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.stopDayTime,
//                       is24HourMode: false,
//                       onChanged: (newValue){
//                         setState(() {
//                           systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.stopDayTime = newValue;
//                         });
//                       }
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       const SizedBox(height: 10,),
//       buildSwitchTile(
//         title: "Pause by days",
//         value: systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.pauseMainLine,
//         onChanged: (newValue) {
//           setState(() {
//             systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.pauseMainLine = newValue;
//           });
//         },
//         icon: Icons.pause,
//       ),
//       const SizedBox(height: 15,),
//       if (systemDefinitionProvider.irrigationLineSystemData![lineIndex].systemDefinition.pauseMainLine)
//         Container(
//           margin: const EdgeInsets.symmetric(horizontal: 15),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(15),
//             color: Colors.white,
//             boxShadow: customBoxShadow
//           ),
//           child: Column(
//             children: [
//               for(var i = 0; i < 7; i++)
//                 buildDayTimePicker(
//                     day: systemDefinitionProvider.days[i],
//                     dayTimeRange: systemDefinitionProvider.daysFromAndToTimes(lineIndex: lineIndex)[i],
//                     dayCount: systemDefinitionProvider.values[i],
//                     checkBoxValue: systemDefinitionProvider.isSelectedList(lineIndex: lineIndex)[i],
//                     constraints: constraints,
//                     lineIndex: lineIndex
//                 )
//             ],
//           ),
//         ),
//     const SizedBox(height: 80,),
//     ],
//   );
// } else {
//   return ListView(
//     shrinkWrap: true,
//     padding: const EdgeInsets.symmetric(horizontal: 10),
//     children: [
//       buildTimerTile(
//           subtitle: "When the power is out for longer than",
//           initialValue: systemDefinitionProvider.irrigationLineSystemData![lineIndex].powerOffRecovery.duration,
//           onChanged: (newValue) {
//             setState(() {
//               systemDefinitionProvider.irrigationLineSystemData![lineIndex].powerOffRecovery.duration = newValue;
//             });
//           },
//           icon: Icons.timer,
//           is24HourMode: true
//       ),
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: List.generate(systemDefinitionProvider.options.length, (index) {
//           return Row(
//             children: [
//               Checkbox(
//                 value: systemDefinitionProvider.irrigationLineSystemData![lineIndex].powerOffRecovery.selectedOption.contains(systemDefinitionProvider.options[index]),
//                 onChanged: (newValue) {
//                   systemDefinitionProvider.updateCheckBoxesForOption(newValue, systemDefinitionProvider.options[index], index, lineIndex);
//                 },
//               ),
//               Text(systemDefinitionProvider.options[index]),
//               const SizedBox(width: 20,)
//             ],
//           );
//         }).toList(),
//       ),
//       const SizedBox(height: 80,),
//     ],
//   );
// }