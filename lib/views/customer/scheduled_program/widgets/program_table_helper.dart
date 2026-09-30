import 'dart:convert';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../modules/IrrigationProgram/state_management/irrigation_program_provider.dart';
import '../../../../modules/IrrigationProgram/view/irrigation_program_main.dart';
import '../../../../services/ai_advisory_service.dart';
import '../../../../services/communication_service.dart';
import '../../../../utils/formatters.dart';
import '../../../../utils/helpers/program_code_helper.dart';
import '../../../../utils/my_function.dart';
import '../../widgets/my_material_button.dart';
import '../../widgets/program_preview.dart';
import 'ai_recommendation_button.dart';


class ProgramTableHelper {
  static List<DataColumn2> columns(BuildContext context, TextStyle headerStyle,
      bool prgOnOffPermission, bool isNova) => [
    DataColumn2(label: Text('Name', style: headerStyle), size: ColumnSize.M),
    DataColumn2(label: Text('Method', style: headerStyle), size: ColumnSize.M),
    DataColumn2(label: Text('Status or Reason', style: headerStyle), size: ColumnSize.L),
    DataColumn2(label: Center(child: Text('Zone', style: headerStyle)), fixedWidth: 50),
    DataColumn2(label: Center(child: Text('Start Date & Time', style: headerStyle)), size: ColumnSize.M),
    DataColumn2(label: Center(child: Text('End Date', style: headerStyle)), size: ColumnSize.S),
    DataColumn2(
      label: isNova ? Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: "Program Preview",
          icon: Icon(Icons.preview, color: Theme.of(context).primaryColor),
          onPressed: () {
            MqttPayloadProvider provider = Provider.of<MqttPayloadProvider>(context, listen: false);
            provider.clearPreview();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              elevation: 10,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              ),
              builder: (_) => const ProgramPreview(isNarrow: false),
            );
          },
        ),
      ) : const Text(''),
      fixedWidth: prgOnOffPermission ? (isNova ? 270 : 315) : 100,
    ),
  ];

  static List<DataRow> rows({
    required List<ProgramList> programs,
    required BuildContext context,
    required AiAdvisoryService aiService,
    required double currentLineSNo,
    required Function showConditionDialog,
    required int userId, customerId,
    required int controllerId,
    required int modelId,
    required int groupId,
    required int categoryId,
    required String deviceId,
    required bool prgOnOffPermission,
    required bool isNova,
  }) {

    var filteredPrograms = currentLineSNo == 0 ? programs : programs.where((p) {
      final irrigationLine = p.irrigationLine;
      return irrigationLine.contains(currentLineSNo) || irrigationLine.isEmpty;
    }).toList();

    return List<DataRow>.generate(filteredPrograms.length, (index) {
      final program = filteredPrograms[index];
      final buttonName = ProgramCodeHelper.getButtonName(int.parse(program.prgOnOff));
      final isStop = buttonName.contains('Stop');
      final isBypass = buttonName.contains('Bypass');

      return DataRow(cells: [
        DataCell(
          SizedBox(
            height: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  program.programName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isNova) ...[
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: program.programStatusPercentage / 100.0,
                          color: Colors.blue.shade300,
                          backgroundColor: Colors.grey.shade200,
                          minHeight: 2.5,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${program.programStatusPercentage}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        DataCell(Text(program.selectedSchedule, style: const TextStyle(fontSize: 11))),
        DataCell(
            Row(
          children: [
            Expanded(
              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(text: 'Start Stop: ', style: TextStyle(color: Colors.black54, fontSize: 12)),
                        TextSpan(text: MyFunction().getContentByCode(program.startStopReason), style: const TextStyle(color: Colors.black, fontSize: 11)),
                      ],
                    ),
                  ),
                  program.pauseResumeReason != 30 ? RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(text: 'Pause Resume: ', style: TextStyle(color: Colors.black54, fontSize: 12)),
                        TextSpan(text: MyFunction().getContentByCode(program.pauseResumeReason), style: const TextStyle(color: Colors.black, fontSize: 11)),
                      ],
                    ),
                  ) :
                  const SizedBox(),
                ],
              ),
            ),
            if (program.conditions.isNotEmpty && program.conditions.any((c) => c.selected))
              IconButton(
                tooltip: 'View Condition',
                onPressed: () => showConditionDialog(context, program.programName,
                    program.conditions.where((c) => c.selected).toList()),
                icon: const Icon(Icons.visibility_outlined),
              ),
          ],
        )),
        DataCell(Center(child: Text('${program.sequence.length}'))),
        DataCell(Center(child: Text('${Formatters().changeDateFormat(program.startDate)} :'
            ' ${MyFunction().convert24HourTo12Hour(program.startTime)}'))),
        DataCell(Center(child: Text(Formatters().changeDateFormat(program.endDate)))),

        if(prgOnOffPermission)...[
          DataCell(
            program.status == 1 ? Row(
              children: [
                SizedBox(
                  height: 27,
                  child: MyMaterialButton(
                    buttonId: '${program.serialNumber}_2900_ss',
                    label: buttonName,
                    payloadKey: "2900",
                    payloadValue: '${program.serialNumber},${program.prgOnOff}',
                    color: int.parse(program.prgOnOff) >= 0 ? isStop ? Colors.red :
                    isBypass ? Colors.orange :
                    Colors.green : Colors.black26,
                    textColor: Colors.white,
                    serverMsg:
                    '${program.programName} ${ProgramCodeHelper.getDescription(int.parse(program.prgOnOff))}',
                  ),
                ),

                if(!isNova)...[
                  const SizedBox(width: 5),
                  SizedBox(
                    height: 27,
                    child: MyMaterialButton(
                      buttonId: '${program.serialNumber}_2900_pr',
                      label: ProgramCodeHelper.getButtonName(int.parse(program.prgPauseResume)),
                      payloadKey: "2900",
                      payloadValue: '${program.serialNumber},${program.prgPauseResume}',
                      color: ProgramCodeHelper.getButtonName(int.parse(program.prgPauseResume)) == 'Pause'
                          ? Colors.orange : Colors.yellow,
                      textColor: ProgramCodeHelper.getButtonName(int.parse(program.prgPauseResume)) == 'Pause'
                          ? Colors.white : Colors.black,
                      serverMsg:
                      '${program.programName} ${ProgramCodeHelper.getDescription(int.parse(program.prgPauseResume))}',
                    ),
                  ),
                ],

                const SizedBox(width: 5),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (result) async{
                    if (result == 'Edit program') {
                      await context.read<IrrigationProgramMainProvider>().programLibraryData(customerId, controllerId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IrrigationProgram(
                            deviceId: deviceId,
                            userId: userId,
                            customerId: customerId,
                            controllerId: controllerId,
                            serialNumber: program.serialNumber,
                            programType: program.programType,
                            fromDealer: false,
                            toDashboard: true,
                            groupId: groupId,
                            categoryId: categoryId,
                            modelId: modelId,
                            deviceName: deviceId,
                            categoryName: '', nodeList: const [],
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Edit program', child: Text('Edit program')),
                    PopupMenuItem(
                      padding: EdgeInsets.zero,
                      child: Builder(
                        builder: (context) {
                          return InkWell(
                            onTap: () async {
                              final RenderBox button = context.findRenderObject() as RenderBox;
                              final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                              final RelativeRect position = RelativeRect.fromRect(
                                Rect.fromPoints(
                                  button.localToGlobal(Offset.zero, ancestor: overlay),
                                  button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                ),
                                Offset.zero & overlay.size,
                              );

                              final selected = await showMenu<String>(
                                context: context,
                                position: position,
                                items: program.sequence.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final seq = entry.value;
                                  final seqName = seq.name;
                                  final seqStatus = seq.isActive;

                                  return PopupMenuItem<String>(
                                    value: seqName,
                                    child: Text(seqName, style: TextStyle(color: seq.isActive? Colors.blue:Colors.black),),
                                    onTap: () {
                                      final payload = '${program.serialNumber},${index + 1}';
                                      final payLoadFinal = jsonEncode({"6700": {"6701": payload}});
                                      Provider.of<CommunicationService>(context, listen: false).sendCommand(
                                        serverMsg: '${program.programName} Changed to $seqName',
                                        payload: payLoadFinal,
                                      );
                                    },
                                  );
                                }).toList(),
                              );

                              Navigator.pop(context); // close parent popup
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Change to'),
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                AiRecommendationButton(aiService: aiService, userId: userId, controllerId: controllerId),
              ],
            ) :
            const Center(child: Text('The program is not ready', style: TextStyle(color: Colors.red))),
          ),
        ] else...[
          const DataCell(
            Center(child: Text('....', style: TextStyle(color: Colors.red))),
          ),
        ]
      ]);
    });
  }
}
