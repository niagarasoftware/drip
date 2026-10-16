import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'package:oro_drip_irrigation/utils/environment.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

import '../../../Constants/constants.dart';
import '../../../models/customer/site_model.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../model/pump_controller_data_model.dart';
import '../widget/custom_countdown_timer.dart';
import 'cycle_details.dart';

class PumpWithValves extends StatelessWidget {
  final PumpValveModel valveData;
  final int dataFetchingStatus;
  final int userId, customerId;
  final MasterControllerModel masterData;
  const PumpWithValves({super.key, required this.valveData, required this.dataFetchingStatus, required this.userId, required this.customerId, required this.masterData});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CustomerScreenControllerViewModel>();
    final valves = masterData.configObjects.where((e) => e.objectId == (AppConstants.pumpWithLightModelList.contains(masterData.modelId) ? 19 :  13)).toList();
    final moistureSensors = provider.mySiteList.data[provider.sIndex].master[provider.mIndex].configObjects.where((e) => e.objectId == 25).toList();
    final bool isPumpWithLight = AppConstants.pumpWithLightModelList.contains(masterData.modelId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 25,
              width: 80,
              decoration: const BoxDecoration(
                // gradient: AppProperties.linearGradientLeading,
                  color: Color(0xffFFA300),
                  borderRadius: BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(3))
              ),
              child: Center(
                child: Text(
                  // '${Provider.of<PreferenceProvider>(context).individualPumpSetting![index].name}',
                  isPumpWithLight ?  "Lights" : "Valves",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white,),
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 15,),
                const SizedBox(width: 5,),
                Text(
                  '${isPumpWithLight ? 'Light' : 'VALVE'} ON MODE : ${valveData.valveOnMode == '1' ? "PROGRAM" : "STANDALONE"}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(width: 10)
          ],
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          shape: const RoundedRectangleBorder(
            side: BorderSide(
              color: Color(0xffFFA300),
              width: 0.5,
            ),
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                topRight: Radius.circular(10)
            ),
          ),
          elevation: 4,
          color: Colors.white,
          surfaceTintColor: Colors.white,
        /*  color: const Color(0xffFFF3D7),
          surfaceTintColor: const Color(0xffFFF3D7),*/
          shadowColor: const Color(0xffFFF3D7),
          child: SizedBox(
            width: MediaQuery.of(context).size.width <= 500 ? MediaQuery.of(context).size.width : 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              // spacing: 10,
              children: [
                // const SizedBox(height: 5,),
                if (valveData.cyclicRestartLimit != '0' && !isPumpWithLight)
                  ...[
                  ValveCycleWidget(
                    valveData: valveData,
                    deviceId: provider.mySiteList.data[provider.sIndex].master[provider.mIndex].deviceId,
                    userId: userId,
                    customerId: customerId,
                    controllerId: masterData.controllerId,
                    dataFetchingStatus: dataFetchingStatus,
                  ),
                  // SizedBox(height: 10,),
                ],
                if(valves.length > 1 && !isPumpWithLight)
                  IntrinsicWidth(
                  child: PopupMenuButton(
                    tooltip: "Select the valve to change",
                    itemBuilder: (BuildContext context) {
                      return [
                        for(int i = 0; i < valves.length; i++)
                          PopupMenuItem(
                            onTap: dataFetchingStatus == 1 ? () async{
                              final Repository repository = Repository(HttpService());
                              final Map<String, dynamic> payload = {"sentSms": "changeto,${i+1}"};
                              MqttService().topicToPublishAndItsMessage(
                                  jsonEncode(payload),
                                  '${Environment.mqttPublishTopic}/${provider.mySiteList.data[provider.sIndex].master[provider.mIndex].deviceId}'
                              );
                              Map<String, dynamic> body = {
                                "userId": customerId,
                                "controllerId": masterData.controllerId,
                                "hardware": payload,
                                "messageStatus": "Change to successfully for ${valves[i].name}",
                                "createUser": userId
                              };
                              await repository.sendManualOperationToServer(body);
                            } : null,
                            child: Text(valves[i].name),
                          ),
                      ];
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(15)
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: const Row(
                          spacing: 5,
                          children: [
                            Icon(Icons.change_circle_outlined, color: Colors.white,),
                            Text('CHANGE TO', style: TextStyle(color: Colors.white, fontSize: 12),),
                          ],
                        )
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: moistureSensors.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    // crossAxisSpacing: 20,
                    // mainAxisSpacing: 20,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, i) {
                    return Column(
                      children: [
                        Image.asset(
                          'assets/Images/Png/objectId_25.png',
                          height: 35,
                          colorBlendMode: BlendMode.modulate,
                        ),
                        Flexible(child: Text(moistureSensors[i].name, style: Theme.of(context).textTheme.titleSmall)),
                        IntrinsicWidth(
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4)),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Text("${valveData.moistureValues.split(',')[i]} cb",
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10,),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: valves.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    // crossAxisSpacing: 20,
                    // mainAxisSpacing: 20,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, i) {
                    var valveItem = valveData.valves['V${i+1}']!;
                    if(dataFetchingStatus != 1) {
                      valveItem.status = '0';
                    }
                    return Column(
                      children: [
                        Builder(
                            builder: (valveContext) {
                              return InkWell(
                                onTap: () => _showDetails(i, valveContext),
                                child: isPumpWithLight ?
                                    Image.asset(
                                        'assets/Images/Png/'
                                            '${valveItem.status == '1'
                                            ? 'bulb_yellow'
                                            : valveItem.status == '0'
                                            ? 'bulb_grey'
                                            : valveItem.status == '2'
                                            ? 'bulb_yellow' : 'bulb_red'}'
                                            '.png',
                                      height: 40,
                                    )
                                    :Image.asset(
                                  'assets/png/independent_valve_gray.png',
                                  height: 40,
                                  color: valveItem.status == '1'
                                      ? Colors.green
                                      : valveItem.status == '0'
                                      ? Colors.grey.shade100
                                      : valveItem.status == '2'
                                      ? Colors.blue
                                      : Colors.red,
                                  colorBlendMode: BlendMode.modulate,
                                ),
                              );
                            }
                        ),
                        Text(valves[i].name, style: Theme.of(context).textTheme.titleSmall, maxLines: 2, textAlign: TextAlign.center,),
                        if (valveItem.status == '1' && valveData.remainingTime != '00:00:00' && dataFetchingStatus == 1)
                          IntrinsicWidth(
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4)),
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: CountdownTimerWidget(
                                key: Key(valveData.remainingTime),
                                initialSeconds: Constants.parseTime(valveData.remainingTime).inSeconds,
                              ),
                            ),
                          )
                      ],
                    );
                  },
                )
              ],
            )
          ),
        ),
      ],
    );
  }

  void _showDetails(int i, BuildContext context) {
    showPopover(
      context: context,
      bodyBuilder: (context) => _buildValveContent(i, context),
      onPop: () {},
      direction: PopoverDirection.bottom,
      arrowHeight: 15,
      arrowWidth: 30,
      barrierColor: Colors.black54,
      width: 150,
      arrowDxOffset: 0,
      transitionDuration: const Duration(milliseconds: 150),
    );
  }

  Widget _buildValveContent(int i, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 5,),
        Text('Valve ${i+1}'),
        Text('Set : ${valveData.valves['V${i+1}']!.duration}'),
        const SizedBox(height: 5,)
        // Text('Actual : 00:00:10')
      ],
    );
  }

  Widget _buildMoistureDetails(context) {
    return Row(
      children: [
        const Icon(Icons.water_drop, color: Colors.blue, size: 15,),
        const SizedBox(width: 5,),
        Text(
          'Moisture : ${valveData.moistureValues}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
