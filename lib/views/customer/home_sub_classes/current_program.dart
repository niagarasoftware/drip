
import 'dart:convert';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/customer/extensions/program_extensions.dart';
import '../../../models/customer/site_model.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../services/communication_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/enums.dart';
import '../../../utils/formatters.dart';
import '../../../utils/snack_bar.dart';
import '../../../view_models/customer/current_program_view_model.dart';

class CurrentProgram extends StatelessWidget {
  const CurrentProgram({super.key, required this.scheduledPrograms, required this.deviceId,
    required this.customerId, required this.controllerId, required this.currentLineSNo,
    required this.modelId, required this.skipPermission});
  final List<ProgramList> scheduledPrograms;
  final String deviceId;
  final int customerId, controllerId, modelId;
  final double currentLineSNo;
  final bool skipPermission;

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (context) => CurrentProgramViewModel(context, currentLineSNo),
      child: Consumer<CurrentProgramViewModel>(
        builder: (context, vm, _) {

          final currentSchedule = context.watch<MqttPayloadProvider>().currentSchedule;

          if(currentSchedule.isNotEmpty){
            WidgetsBinding.instance.addPostFrameCallback((_) {
              vm.updateSchedule(currentSchedule, false);
            });
          }

          return vm.currentSchedule.isNotEmpty && vm.currentSchedule[0].isNotEmpty?
          buildWebTable(context, vm.currentSchedule) :
          const SizedBox();
        },
      ),
    );

  }

  Widget buildWebTable(BuildContext context, List<String> schedule) {

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                  height: (schedule.length * 45) + 45,
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 1100,
                    dataRowHeight: 45.0,
                    headingRowHeight: 40.0,
                    headingRowColor: WidgetStateProperty.all<Color>(Colors.green.shade50),
                    columns: [
                      const DataColumn2(
                        label: Text('Name', style: TextStyle(fontSize: 13)),
                        size: ColumnSize.M,
                      ),
                      const DataColumn2(
                        label: Text('Zone', style: TextStyle(fontSize: 13)),
                        fixedWidth: 75,
                      ),
                      const DataColumn2(
                        label: Text('Zone Name', style: TextStyle(fontSize: 13)),
                        size: ColumnSize.S,
                      ),
                      const DataColumn2(
                        label: Center(child: Text('RTC', style: TextStyle(fontSize: 13))),
                        fixedWidth: 75,
                      ),
                      const DataColumn2(
                        label: Center(child: Text('Cyclic', style: TextStyle(fontSize: 13))),
                        fixedWidth: 75,
                      ),
                      const DataColumn2(
                        label: Center(child: Text('Started at', style: TextStyle(fontSize: 13))),
                        size: ColumnSize.S,
                      ),
                      const DataColumn2(
                        label: Center(child: Text('Set (Dur/Flw)', style: TextStyle(fontSize: 13))),
                        fixedWidth: 100,
                      ),
                      const DataColumn2(
                        label: Center(child: Text('Avg/Flw Rate', style: TextStyle(fontSize: 13))),
                        fixedWidth: 100,
                      ),
                      const DataColumn2(
                        label: Center(child: Text('Remaining', style: TextStyle(fontSize: 13))),
                        size: ColumnSize.S,
                      ),
                      if(![...AppConstants.ecoGemModelList].contains(modelId))...const [
                        DataColumn2(label: Center(child: Text('')), fixedWidth: 90),
                      ]
                    ],
                    rows: List<DataRow>.generate(schedule.length, (index) {
                      List<String> values = schedule[index].split(",");

                      final programName = scheduledPrograms.getProgramName(values[0]);
                      final sequenceName = scheduledPrograms.getSequenceName(values[0], values[1]);

                      return DataRow(cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(programName),
                              Text(
                                getContentByCode(int.parse(values[15])),
                                style: const TextStyle(fontSize: 10, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text('${values[10]}/${values[9]}')),
                        DataCell(Text(
                          programName == 'StandAlone - Manual' ? '--' : sequenceName,
                        )),
                        DataCell(Center(child: Text(Formatters().formatRtcValues(values[6], values[5])))),
                        DataCell(Center(child: Text(Formatters().formatRtcValues(values[8], values[7])))),
                        DataCell(Center(child: Text(convert24HourTo12Hour(values[11])))),
                        DataCell(Center(child: Text(programName == 'StandAlone - Manual' &&
                            (values[3] == '00:00:00' || values[3] == '0') ? 'Timeless' : values[3]))),
                        DataCell(Center(child: Text('${values[16]} l/s'))),
                        DataCell(Center(child: Text(programName == 'StandAlone - Manual' &&
                              (values[3] == '00:00:00' || values[3] == '0')
                              ? '----'
                              : values[4],
                          style: const TextStyle(fontSize: 20),
                        ))),

                        if(skipPermission)...[
                          if(![...AppConstants.ecoGemModelList].contains(modelId))...[
                            DataCell(Center(child: buildActionButton(context, values))),
                          ]
                        ]else...[
                          if(![...AppConstants.ecoGemModelList].contains(modelId))...[
                            const DataCell(Center(child: Text('...'))),
                          ]
                        ]
                      ]);
                    }),
                  ),
                ),
              ),
              Positioned(
                top: 5,
                left: 0,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                      border: Border.all(width: 0.5, color: Colors.grey)),
                  child: const Text('CURRENT SCHEDULE', style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget buildActionButton(BuildContext context, List<String> values) {

    final programName = scheduledPrograms.getProgramName(values[0]);
    final programRnReason = getContentByCode(int.parse(values[15]));
    final sequenceName = scheduledPrograms.getSequenceName(values[0], values[1]);


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
    } else if (programName.contains('StandAlone')) {
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
    }else if (programRnReason.contains('Program started manually')) {
      return MaterialButton(
        color: Colors.redAccent,
        textColor: Colors.white,
        onPressed: () async {

          String payLoadFinal = jsonEncode({
            "3900": {"3901": '0,${values[0]},${values[1]},0,0,0,0,0,0,0,0'}
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

          GlobalSnackBar.show(context, 'Comment sent successfully', 200);
        } : null,
        child: const Text('Skip', style: TextStyle(color: Colors.white, fontSize: 13)),
      );
    }
  }

  Widget buildScheduleRow(BuildContext context, List<String> values) {

    final programName = scheduledPrograms.getProgramName(values[0]);
    final sequenceName = scheduledPrograms.getSequenceName(values[0], values[1]);

    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: 143,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: 35,
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 3),
                    child: SizedBox(
                      width: 105,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name & Method',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text('$programName - ${scheduledPrograms[0].selectedSchedule}'),
                        Text(getContentByCode(int.parse(values[17])), style: const TextStyle(fontSize: 11, color: Colors.black54),),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: SizedBox(
                    width: 105,
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
                      sequenceName ?? '--'),
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
                    width: 105,
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
                          Text(convert24HourTo12Hour(values[11])),
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
                      SizedBox(
                        width: 225,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Spacer(),
                            Container(
                              width: 1,
                              height: 70,
                              color: Colors.black12,
                            ),
                            const Spacer(),
                            Column(
                              children: [
                                const Text('Remaining', style: TextStyle(color: Colors.black45)),
                                Padding(
                                  padding: const EdgeInsets.only(top:2, bottom: 5),
                                  child: Container(
                                    width: 75,
                                    height: 1,
                                    color: Colors.black12,
                                  ),
                                ),
                                Center(child: Text(
                                  programName == 'StandAlone - Manual' &&
                                      (values[3] == '00:00:00' || values[3] == '0')
                                      ? '----'
                                      : values[4],
                                  style: const TextStyle(fontSize: 20),
                                )),
                              ],
                            ),
                            const Spacer(),
                            if(![...AppConstants.ecoGemModelList].contains(modelId))...[
                              buildActionButton(context, values),
                              const Spacer(),
                            ],
                          ],
                        ),
                      ),
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

  String convert24HourTo12Hour(String timeString) {
    if(timeString=='-'){
      return '-';
    }
    final parsedTime = DateFormat('HH:mm:ss').parse(timeString);
    final formattedTime = DateFormat('hh:mm a').format(parsedTime);
    return formattedTime;
  }

  String getContentByCode(int code) {
    return GemProgramStartStopReasonCode.fromCode(code).content;
  }

}