import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/utils/formatters.dart';
import 'package:oro_drip_irrigation/utils/helpers/mc_permission_helper.dart';
import 'package:oro_drip_irrigation/views/customer/scheduled_program/widgets/ai_recommendation_button.dart';
import 'package:oro_drip_irrigation/views/customer/scheduled_program/widgets/program_updater.dart';
import 'package:provider/provider.dart';

import '../../../models/customer/site_model.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../modules/IrrigationProgram/view/irrigation_program_main.dart';
import '../../../services/ai_advisory_service.dart';
import '../../../services/communication_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/helpers/program_code_helper.dart';
import '../../../utils/my_function.dart';
import '../../../view_models/customer/customer_screen_controller_view_model.dart';
import '../widgets/my_material_button.dart';
import '../widgets/program_preview.dart';

class ScheduledProgramNarrow extends StatefulWidget {
  const ScheduledProgramNarrow({super.key, required this.userId,
    required this.customerId, required this.currentLineSNo, required this.groupId,
    required this.master});

  final int userId, customerId, groupId;
  final double currentLineSNo;
  final MasterControllerModel master;

  static const headerStyle = TextStyle(fontSize: 13);

  @override
  State<ScheduledProgramNarrow> createState() => _ScheduledProgramNarrowState();
}

class _ScheduledProgramNarrowState extends State<ScheduledProgramNarrow> {

  late final AiAdvisoryService aiService;

  @override
  void initState() {
    super.initState();
    aiService = AiAdvisoryService();
  }

  @override
  Widget build(BuildContext context) {

    final viewModel = context.watch<CustomerScreenControllerViewModel>();
    final master = viewModel.mySiteList.data[viewModel.sIndex].master[viewModel.mIndex];
    bool isNova = [...AppConstants.ecoGemModelList].contains(master.modelId);
    final hasProgramOnOff = master.getPermissionStatus("Program On/Off Manually");

    final spLive = context.watch<MqttPayloadProvider>().scheduledProgramPayload;
    final conditionPayload = context.watch<MqttPayloadProvider>().conditionPayload;

    if (spLive.isNotEmpty) {
      ProgramUpdater.updateProgramsFromMqtt(spLive, master.programList, conditionPayload);
    }

    var filteredScheduleProgram = widget.currentLineSNo == 0 ? master.programList :
    master.programList.where((program) {
      final irrigationLine = program.irrigationLine;
      return irrigationLine.contains(widget.currentLineSNo) || irrigationLine.isEmpty;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: filteredScheduleProgram.isNotEmpty? Column(
        children: [
          if(isNova)...[
            ListTile(
              title: const Text('Program preview'),
              trailing: IconButton(
                tooltip: "Program Preview",
                icon: Icon(Icons.preview, color: Theme.of(context).primaryColor),
                onPressed: () {
                  MqttPayloadProvider provider = Provider.of<MqttPayloadProvider>(context, listen: false);
                  provider.clearPreview();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                    builder: (_) => AnnotatedRegion<SystemUiOverlayStyle>(
                      value: SystemUiOverlayStyle(
                        statusBarColor: Theme.of(context).primaryColor,
                        statusBarIconBrightness: Brightness.light,
                      ),
                      child: const ProgramPreview(isNarrow: true),
                    ),
                  );
                },
              ),
            )
          ],
          Expanded(
            child: ListView.builder(
              itemCount: filteredScheduleProgram.length,
              itemBuilder: (context, index) {
                final program = filteredScheduleProgram[index];
                final buttonName = ProgramCodeHelper.getButtonName(int.parse(program.prgOnOff));
                final isStop = buttonName.contains('Stop');
                final isBypass = buttonName.contains('Bypass');

                return  Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Name & progress', style: TextStyle(fontSize: 13, color: Colors.black54),),
                                  SizedBox(height: 10,),
                                  Text('Method', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                  SizedBox(height: 5,),
                                  Text('Status or Reason', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                  SizedBox(height: 5,),
                                  Text('Total Sequence', style: TextStyle(fontSize: 13, color: Colors.black54),),
                                  SizedBox(height: 5,),
                                  Text('Start Date & Time', style: TextStyle(fontSize: 13, color: Colors.black54),),
                                  SizedBox(height: 5,),
                                  Text('End Date', style: TextStyle(fontSize: 13, color: Colors.black54),),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: SizedBox(
                                width: 10,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(':'),
                                    SizedBox(height: 10,),
                                    Text(':'),
                                    SizedBox(height: 5,),
                                    Text(':'),
                                    SizedBox(height: 5,),
                                    Text(':'),
                                    SizedBox(height: 5,),
                                    Text(':'),
                                    SizedBox(height: 5,),
                                    Text(':'),
                                  ],
                                ),
                              ),
                            ),
                            Flexible(
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(program.programName),
                                            if(!isNova)...[
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: LinearProgressIndicator(
                                                      value: program.programStatusPercentage / 100.0,
                                                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                                                      color: Colors.blue.shade300,
                                                      backgroundColor: Colors.grey.shade200,
                                                      minHeight: 3,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Text(
                                                    '${program.programStatusPercentage}%',
                                                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                                                  ),
                                                ],
                                              ),
                                            ]

                                          ],
                                        ),
                                      ),
                                      (filteredScheduleProgram[index].conditions.isNotEmpty &&
                                          filteredScheduleProgram[index].conditions.any((c) => c.selected == true)) // ✅ check if any selected
                                          ? IconButton(
                                        tooltip: 'View Condition',
                                        onPressed: () {
                                          final selectedConditions = filteredScheduleProgram[index]
                                              .conditions
                                              .where((c) => c.selected == true)
                                              .toList();

                                          showConditionDialog(
                                            context,
                                            filteredScheduleProgram[index].programName,
                                            selectedConditions,
                                          );
                                        },
                                        icon: const Icon(Icons.visibility_outlined),
                                      )
                                          : const SizedBox(),
                                    ],
                                  ),
                                  Text(filteredScheduleProgram[index].selectedSchedule, style: const TextStyle(fontSize: 11)),
                                  const SizedBox(height: 5,),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 12, color: Colors.black),
                                          children: [
                                            const TextSpan(text: 'Start Stop: ', style: TextStyle(color: Colors.black54)),
                                            TextSpan(text: MyFunction().getContentByCode(program.startStopReason)),
                                          ],
                                        ),
                                      ),
                                      if (program.pauseResumeReason != 30)
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(fontSize: 12, color: Colors.black),
                                            children: [
                                              const TextSpan(text: 'Pause Resume: ', style: TextStyle(color: Colors.black54)),
                                              TextSpan(text: MyFunction().getContentByCode(program.pauseResumeReason)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5,),
                                  SizedBox(width: 50, child: Text('${program.sequence.length}')),
                                  const SizedBox(height: 5,),
                                  Text('${Formatters().changeDateFormat(program.startDate)} : ${MyFunction().convert24HourTo12Hour(program.startTime)}'),
                                  const SizedBox(height: 5,),
                                  Text(Formatters().changeDateFormat(program.endDate)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if(hasProgramOnOff)...[
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width,
                            child: program.status == 1? Row(
                              children: [
                                const Spacer(),
                                MyMaterialButton(
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
                                const SizedBox(width: 8),
                                if(!isNova)...[
                                  MyMaterialButton(
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
                                  const SizedBox(width: 5),
                                ],
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (result) {
                                    if (result == 'Edit program') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => IrrigationProgram(
                                            deviceId: widget.master.deviceId,
                                            userId: widget.userId,
                                            controllerId: widget.master.controllerId,
                                            serialNumber: widget.master.programList[index].serialNumber,
                                            programType: filteredScheduleProgram[index].programType,
                                            fromDealer: false,
                                            toDashboard: true,
                                            groupId: widget.groupId,
                                            categoryId: widget.master.categoryId,
                                            customerId: widget.customerId,
                                            modelId: widget.master.modelId,
                                            deviceName: widget.master.deviceName,
                                            categoryName: widget.master.categoryName,
                                            nodeList: const [],
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

                                              await showMenu<String>(
                                                context: context,
                                                position: position,
                                                items: program.sequence.asMap().entries.map((entry) {
                                                  final index = entry.key;
                                                  final seq = entry.value;
                                                  final seqName = seq.name; // or whatever your display property is

                                                  return PopupMenuItem<String>(
                                                    value: seqName,
                                                    child: Text(seqName),
                                                    onTap: () {
                                                      final payload = '${program.serialNumber},${index + 1}';
                                                      final payLoadFinal = jsonEncode({"6700": {"6701": payload}});
                                                      Provider.of<CommunicationService>(context, listen: false)
                                                          .sendCommand(
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
                                AiRecommendationButton(aiService: aiService, userId: widget.userId, controllerId: widget.master.controllerId),
                              ],
                            ):
                            const Center(child: Text('The program is not ready', style: TextStyle(color: Colors.red))),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ):
      const Center(child: Text('Program not found')),
    );
  }

  void showConditionDialog(BuildContext context, String prgName, List<ConditionModel> conditions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                conditions.length > 1 ? 'Conditions of $prgName' : 'Condition of $prgName',
                style: const TextStyle(fontSize: 17),
              ),
              content: SizedBox(
                width: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: conditions.length,
                  itemBuilder: (context, index) {
                    final cond = conditions[index];
                    return ListTile(
                      title: Text(
                        cond.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cond.conditionStatus == 1 ? Colors.green : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        cond.value.rule,
                        style: TextStyle(
                          color: cond.conditionStatus == 1 ? Colors.green.shade700 : Colors.black54,
                        ),
                      ),
                      trailing: Text('Actual\n${cond.value.actualValue}'),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}