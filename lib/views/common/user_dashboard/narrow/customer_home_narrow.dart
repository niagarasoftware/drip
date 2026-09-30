import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/utils/helpers/mc_permission_helper.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

import '../../../../Widgets/pump_widget.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../services/communication_service.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/formatters.dart';
import '../../../../utils/my_function.dart';
import '../../../../utils/snack_bar.dart';
import '../../../../view_models/customer/current_program_view_model.dart';
import '../../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../../../customer/widgets/my_material_button.dart';
import '../../../customer/widgets/sensor_widget_mobile.dart';
import '../widgets/aquaculture_line.dart';
import '../widgets/irrigation_line_narrow.dart';
import '../widgets/oms_line.dart';
import '../widgets/pump_station_mobile.dart';
import '../widgets/valve_status_legend.dart';

class CustomerHomeNarrow extends StatelessWidget {
  const CustomerHomeNarrow({super.key});


  @override
  Widget build(BuildContext context) {

    final viewModel = Provider.of<CustomerScreenControllerViewModel>(context);
    int customerId = viewModel.mySiteList.data[viewModel.sIndex].customerId;
    final cM = viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex];

    bool isNova = [...AppConstants.ecoGemModelList].contains(cM.modelId);
    bool isAquaculture = [...AppConstants.aquacultureModelList].contains(
        cM.modelId);

    bool isOMS = [...AppConstants.omsGemList].contains(cM.modelId);

    final linesToDisplay = (viewModel.myCurrentIrrLine == "All irrigation line" ||
        viewModel.myCurrentIrrLine == "All Aquaculture line" || viewModel.myCurrentIrrLine.isEmpty)
        ? cM.irrigationLine.where((line) => line.name != viewModel.myCurrentIrrLine).toList()
        : cM.irrigationLine.where((line) => line.name == viewModel.myCurrentIrrLine).toList();

    final hasProgramOnOff = cM.getPermissionStatus("Program On/Off Manually");
    final hasLinePP = cM.getPermissionStatus("Irrigation Line Pause/Resume Manually");


    return Scaffold(
      backgroundColor: Colors.white70,
      body: RefreshIndicator(
        onRefresh: () async {
          await viewModel.onRefreshClicked();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 130),
          child: isOMS ? buildOMSLine (cM, customerId, cM.controllerId, cM.modelId, cM.deviceId,
              viewModel.mySiteList.data[viewModel.sIndex].groupId) : Column(
            children: [

              Consumer<CustomerScreenControllerViewModel>(
                builder: (context, viewModel, _) {
                  return viewModel.onRefresh ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: LinearProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      backgroundColor: Colors.grey[200],
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ) : const SizedBox();
                },
              ),

              buildValveStatusLegend(isAquaculture),

              if(isNova)...[
                const Padding(
                  padding: EdgeInsets.only(left: 10, right: 10, top: 5),
                  child: Card(
                      elevation: 1,
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      child: VoltageWidget()),
                ),
              ],

              ...linesToDisplay.map((line) {

                if(isAquaculture) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.sizeOf(context).width,
                        color: Colors.grey.shade200,
                        height: 45,
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Text(
                              line.name,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (hasLinePP) ...[
                              const Spacer(),
                              SizedBox(
                                height: 35,
                                child: MyMaterialButton(
                                  buttonId: 'line_${line.sNo}_4900',
                                  label: line.linePauseFlag == 0 ? 'Pause the line' : 'Resume the line',
                                  payloadKey: "4900",
                                  payloadValue: "${line.sNo},${line.linePauseFlag == 0 ? 1 : 0}",
                                  color: line.linePauseFlag == 0 ? Colors.orangeAccent : Colors.green,
                                  textColor: Colors.white,
                                  serverMsg: line.linePauseFlag == 0
                                      ? 'Paused the ${line.name}'
                                      : 'Resumed the ${line.name}',
                                  blink: line.linePauseFlag != 0,
                                ),
                              ),
                              const SizedBox(width: 5)
                            ]
                          ],
                        ),
                      ),
                      AquacultureLine(irrLine: line, customerId: customerId,
                          controllerId: cM.controllerId, modelId: cM.modelId, deviceId: cM.deviceId),],
                  );
                }

                final inletWaterSources = {
                  for (var source in line.inletSources) source.sNo: source
                }.values.toList();

                final outletWaterSources = {
                  for (var source in line.outletSources) source.sNo: source
                }.values.toList();

                final cFilterSite = {
                  if (line.centralFilterSite != null) line.centralFilterSite!.sNo : line.centralFilterSite!
                }.values.toList();

                final cFertilizerSite = {
                  if (line.centralFertilizerSite != null) line.centralFertilizerSite!.sNo : line.centralFertilizerSite!
                }.values.toList();

                final lFilterSite = {
                  if (line.localFilterSite != null) line.localFilterSite!.sNo : line.localFilterSite!
                }.values.toList();

                final lFertilizerSite = {
                  if (line.localFertilizerSite != null) line.localFertilizerSite!.sNo : line.localFertilizerSite!
                }.values.toList();

                final prsSwitch = [
                  ..._buildSensorItems(line.prsSwitch, 'Pressure Switch', 'assets/png/pressure_switch_wj.png', false,
                      customerId, cM.controllerId),
                ];

                return Padding(
                  padding: const EdgeInsets.all(5),
                  child: Stack(
                    children: [
                      Positioned(
                        top: !isNova ? 49 : 4,
                        left: 2,
                        bottom: 72,
                        child: Container(width: 4, color: Colors.grey.shade300),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isNova) ...[
                                  Container(
                                    width: MediaQuery.sizeOf(context).width,
                                    color: Colors.grey.shade200,
                                    height: 45,
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 16),
                                        Text(
                                          line.name,
                                          textAlign: TextAlign.left,
                                          style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (hasLinePP) ...[
                                          const Spacer(),
                                          SizedBox(
                                            height: 35,
                                            child: MyMaterialButton(
                                              buttonId: 'line_${line.sNo}_4900',
                                              label: line.linePauseFlag == 0 ? 'Pause the line' : 'Resume the line',
                                              payloadKey: "4900",
                                              payloadValue: "${line.sNo},${line.linePauseFlag == 0 ? 1 : 0}",
                                              color: line.linePauseFlag == 0 ? Colors.orangeAccent : Colors.green,
                                              textColor: Colors.white,
                                              serverMsg: line.linePauseFlag == 0
                                                  ? 'Paused the ${line.name}'
                                                  : 'Resumed the ${line.name}',
                                              blink: line.linePauseFlag != 0,
                                            ),
                                          ),
                                          const SizedBox(width: 5)
                                        ]
                                      ],
                                    ),
                                  ),
                                ],
                                Padding(
                                  padding: const EdgeInsets.only(left: 5, top: 3, bottom: 3),
                                  child: PumpStationMobile(
                                    inletWaterSources: inletWaterSources,
                                    outletWaterSources: outletWaterSources,
                                    cFilterSite: cFilterSite,
                                    cFertilizerSite: cFertilizerSite,
                                    lFilterSite: lFilterSite,
                                    lFertilizerSite: lFertilizerSite,
                                    customerId: customerId,
                                    controllerId: cM.controllerId,
                                    deviceId: cM.deviceId,
                                    modelId: cM.modelId,
                                    isNova: isNova,
                                  ),
                                ),
                                if (prsSwitch.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5, top: 5, bottom: 5),
                                    child: Wrap(
                                      alignment: WrapAlignment.start,
                                      spacing: 0,
                                      runSpacing: 0,
                                      children: prsSwitch,
                                    ),
                                  ),
                                ],
                                IrrigationLineNarrow(
                                  valves: line.valveObjects,
                                  mainValves: line.mainValveObjects,
                                  lights:line.lightObjects,
                                  fans:line.fanObjects,
                                  gates:line.gateObjects,
                                  pressureIn: line.pressureIn,
                                  pressureOut: line.pressureOut,
                                  waterMeter: line.waterMeter,
                                  co2: line.co2Sensor,
                                  humidity: line.humiditySensor,
                                  temperature: line.temperature,
                                  soilTemperature: line.soilTemperature,
                                  customerId: customerId,
                                  controllerId: cM.controllerId,
                                  deviceId: cM.deviceId,
                                  modelId: cM.modelId,
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),

      floatingActionButton: SizedBox(
        height: 65,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 5, right: 100),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChangeNotifierProvider(
                create: (context) => CurrentProgramViewModel(
                  context,
                  viewModel.mySiteList.data[viewModel.sIndex]
                      .master[viewModel.mIndex]
                      .irrigationLine[viewModel.lIndex]
                      .sNo,
                ),
                child: Consumer<CurrentProgramViewModel>(
                  builder: (context, vm, _) {
                    final currentSchedule = context.watch<MqttPayloadProvider>().currentSchedule;

                    if (currentSchedule.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        vm.updateSchedule(currentSchedule, false);
                      });
                    }

                    if (vm.currentSchedule.isNotEmpty &&
                        vm.currentSchedule[0].isNotEmpty) {
                      return buildCurrentSchedule(context, vm.currentSchedule,
                          cM.programList, cM.modelId, hasProgramOnOff);
                    } else {
                      return const SizedBox();
                    }
                  },
                ),
              ),
              buildNextScheduleCard(context, cM.programList),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartDocked,

    );
  }

  Widget buildOMSLine(MasterControllerModel master,
      int customerId, int controllerId, int modelId, String deviceId, int groupId){

    return OmsLine(customerId: customerId,
        controllerId: controllerId, modelId: modelId, deviceId: deviceId, master: master, groupId: groupId, isNarrow: true);

  }

  List<Widget> _buildSensorItems(List<SensorModel> sensors, String type, String imagePath, bool isAvailFertilizer,
      int customerId, int controllerId) {
    return sensors.map((sensor) {
      return Padding(
        padding: EdgeInsets.only(top: isAvailFertilizer? 30 : 0),
        child: SensorWidgetMobile(
          sensor: sensor,
          sensorType: type,
          imagePath: imagePath,
          customerId: customerId,
          controllerId: controllerId,
        ),
      );
    }).toList();
  }

  Widget buildCurrentSchedule(BuildContext context,
      List<String> currentSchedule, List<ProgramList> scheduledPrograms, int modelId, bool hasSkip) {
    return Row(
      children: List.generate(currentSchedule.length, (index) {
        List<String> values = currentSchedule[index].split(',');

        final programName = MyFunction().getProgramNameById(int.parse(values[0]), scheduledPrograms);
        final isManual = programName == 'StandAlone - Manual';
        final timeless = (values[3] == '00:00:00' || values[3] == '0');

        return Builder(
          builder: (rowContext) {
            return GestureDetector(
              onTap: () {
                showPopover(
                  context: rowContext,
                  bodyBuilder: (context) =>  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: buildScheduleRow(context, values, programName, scheduledPrograms, modelId, hasSkip),
                  ),
                  onPop: () => debugPrint('Popover was popped!'),
                  direction: PopoverDirection.top,
                  width: 350,
                  height: 150,
                  arrowHeight: 15,
                  arrowWidth: 30,
                );
              },
              child: Card(
                color: Colors.white,
                elevation: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                  ),
                  child: SizedBox(
                    height: 45,
                    child: Column(
                      children: [
                        Text(programName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        Text(
                          isManual && timeless ? 'Timeless' : values[4],
                          style:
                          const TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget buildScheduleRow(BuildContext context, List<String> values, String programName,
      List<ProgramList> scheduledPrograms, int modelId, bool hasSkip) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: 143,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: 20,
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 3),
                    child: SizedBox(
                      width: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Method',
                            style: TextStyle(
                              color: Colors.black45,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(':'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text( MyFunction().getContentByCode(int.parse(values[15])), style: const TextStyle(fontSize: 11, color: Colors.black54),),
                  )
                ],
              ),
            ),
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: SizedBox(
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Zone', style: TextStyle(color: Colors.black45)),
                        SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(':'),
                      SizedBox(height: 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(programName == 'StandAlone - Manual' ? '--' :
                      MyFunction().getSequenceName(int.parse(values[0]), values[1], scheduledPrograms) ?? '--',),
                      const SizedBox(height: 3),
                    ],
                  ),
                )
              ],
            ),
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: SizedBox(
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Started at', style: TextStyle(color: Colors.black45)),
                        SizedBox(height: 2),
                        Text('Current Zone', style: TextStyle(color: Colors.black45)),
                        SizedBox(height: 2),
                        Text('Rtc & Cyclic', style: TextStyle(color: Colors.black45)),
                        SizedBox(height: 2),
                        Text('Set (Dur/Flw)', style: TextStyle(color: Colors.black45)),
                        SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(':'),
                      SizedBox(height: 2),
                      Text(':'),
                      SizedBox(height: 2),
                      Text(':'),
                      SizedBox(height: 2),
                      Text(':'),
                      SizedBox(height: 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(MyFunction().convert24HourTo12Hour(values[11])),
                          const SizedBox(height: 2),
                          Text('${values[10]} of ${values[9]}'),
                          const SizedBox(height: 1),
                          Text('${Formatters().formatRtcValues(values[6], values[5])} - ${Formatters().formatRtcValues(values[8], values[7])}'),
                          const SizedBox(height: 3),
                          Text(programName == 'StandAlone - Manual' && (values[3] == '00:00:00' || values[3] == '0')
                              ? 'Timeless'
                              : values[3]),
                          const SizedBox(height: 2),
                        ],
                      ),
                      if(hasSkip)...[
                        SizedBox(
                          width: 130,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Spacer(),
                              if(![...AppConstants.ecoGemModelList].contains(modelId))...[
                                buildActionButton(context, values, programName, programName == 'StandAlone - Manual' ? '--' :
                                MyFunction().getSequenceName(int.parse(values[0]), values[1], scheduledPrograms) ?? '--',),
                              ],
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionButton(BuildContext context,
      List<String> values, String  programName, String  sequenceName) {

    if (programName == 'StandAlone - Manual') {
      return MaterialButton(
        color: Colors.redAccent,
        textColor: Colors.white,
        onPressed: values[17]=='1'? () async {
          String payLoadFinal = jsonEncode({
            "800": {"801": '0,0,0,0,0'}
          });

          final result = await context.read<CommunicationService>().sendCommand(
              serverMsg: '$programName Stopped manually',
              payload: payLoadFinal);

          if (result['http'] == true) debugPrint("Payload sent to Server");
          if (result['mqtt'] == true) debugPrint("Payload sent to MQTT Box");
          if (result['bluetooth'] == true) debugPrint("Payload sent via Bluetooth");

          GlobalSnackBar.show(context, 'Comment sent successfully', 200);
        }: null,
        child: const Text('Stop'),
      );
    } else if (programName.contains('StandAlone'))  {
      return MaterialButton(
        color: Colors.redAccent,
        textColor: Colors.white,
        onPressed: () async {

          String payLoadFinal = jsonEncode({
            "3900": {"3901": '0,${values[3]},${values[0]},'
                '${values[1]},,,,,,,0'}
          });

          final result = await context.read<CommunicationService>().sendCommand(
              serverMsg: '$programName Stopped manually',
              payload: payLoadFinal);

          if (result['http'] == true) debugPrint("Payload sent to Server");
          if (result['mqtt'] == true) debugPrint("Payload sent to MQTT Box");
          if (result['bluetooth'] == true) debugPrint("Payload sent via Bluetooth");

          GlobalSnackBar.show(context, 'Comment sent successfully', 200);

        },
        child: const Text('Stop'),
      );
    }else{
      return MaterialButton(
        color: Colors.orangeAccent,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        onPressed: values[17]=='1' ? () async {
          String payload = '${values[18]},0';
          String payLoadFinal = jsonEncode({
            "3700": {"3701": payload}
          });

          final result = await context.read<CommunicationService>().sendCommand(
              serverMsg: '$programName - $sequenceName skipped manually',
              payload: payLoadFinal);

          if (result['http'] == true) debugPrint("Payload sent to Server");
          if (result['mqtt'] == true) debugPrint("Payload sent to MQTT Box");
          if (result['bluetooth'] == true) debugPrint("Payload sent via Bluetooth");

          Navigator.pop(context);
          GlobalSnackBar.show(context, 'Comment sent successfully', 200);

        } : null,
        child: const Text('Skip', style: TextStyle(color: Colors.white, fontSize: 13)),
      );
    }
  }

  Widget displayLinearProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 3, right: 3),
      child: LinearProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        backgroundColor: Colors.grey[200],
        minHeight: 4,
        borderRadius: BorderRadius.circular(5.0),
      ),
    );
  }

  Widget buildNextScheduleCard(BuildContext context, List<ProgramList> scheduledPrograms) {

    var nextSchedule =  context.watch<MqttPayloadProvider>().nextSchedule;

    if(nextSchedule.isNotEmpty && nextSchedule[0].isNotEmpty){
      return Row(
        children: List.generate(nextSchedule.length, (index) {

          List<String> values = nextSchedule[index].split(',');

          final programName =  MyFunction().getProgramNameById(int.parse(values[0]), scheduledPrograms);
          final sqName =  MyFunction().getSequenceName(int.parse(values[0]), values[1], scheduledPrograms) ?? '--';

          return Builder(
            builder: (rowContext) {
              return GestureDetector(
                onTap: () {
                  showPopover(
                    context: rowContext,
                    bodyBuilder: (context) =>  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: buildNextScheduleRow(context, values, programName, sqName),
                    ),
                    onPop: () => debugPrint('Popover was popped!'),
                    direction: PopoverDirection.top,
                    width: 300,
                    height: 90,
                    arrowHeight: 15,
                    arrowWidth: 30,
                  );
                },
                child: Card(
                  color: Colors.white,
                  elevation: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade300,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                    ),
                    child: SizedBox(
                      height: 45,
                      child: Column(
                        children: [
                          const Text('Next Shift',
                              style: TextStyle(color: Colors.black45, fontSize: 13)),
                          const SizedBox(height: 3),
                          Text(sqName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );

        }),
      );
    }else{
      return const SizedBox();
    }
  }

  Widget buildNextScheduleRow(BuildContext context, List<String> values,
      String programName, String sequenceName) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: SizedBox(
            width: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Program Name', style: TextStyle(color: Colors.black45)),
                SizedBox(height: 2),
                Text('Start at', style: TextStyle(color: Colors.black45)),
                SizedBox(height: 2),
                Text('Set (Dur/Flw)', style: TextStyle(color: Colors.black45)),
                SizedBox(height: 2),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(programName),
                const SizedBox(height: 1),
                Text(MyFunction().convert24HourTo12Hour(values[6])),
                const SizedBox(height: 3),
                Text(values[3]),
                const SizedBox(height: 2),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class LinePositionResult {
  final List<double> positions;
  final double startPosition;

  LinePositionResult(this.positions, this.startPosition);
}