import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/views/customer/scheduled_program/widgets/program_table_helper.dart';
import 'package:oro_drip_irrigation/views/customer/scheduled_program/widgets/program_updater.dart';
import 'package:provider/provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';
import '../../../services/ai_advisory_service.dart';
import '../../../utils/constants.dart';


class ScheduledProgramWide extends StatefulWidget {
  const ScheduledProgramWide({super.key, required this.userId,
    required this.scheduledPrograms, required this.controllerId,
    required this.deviceId, required this.customerId,
    required this.currentLineSNo, required this.groupId,
    required this.categoryId, required this.modelId,
    required this.deviceName, required this.categoryName, required this.prgOnOffPermission});

  final int userId, customerId, controllerId, groupId, categoryId, modelId;
  final String deviceId, deviceName, categoryName;
  final List<ProgramList> scheduledPrograms;
  final double currentLineSNo;
  final bool prgOnOffPermission;

  static const headerStyle = TextStyle(fontSize: 13);

  @override
  State<ScheduledProgramWide> createState() => _ScheduledProgramWideState();
}

class _ScheduledProgramWideState extends State<ScheduledProgramWide> {
  late final AiAdvisoryService aiService;

  @override
  void initState() {
    super.initState();
    aiService = AiAdvisoryService();
  }

  @override
  Widget build(BuildContext context) {

    bool isNova = [...AppConstants.ecoGemModelList].contains(widget.modelId);

    final spLive = Provider.of<MqttPayloadProvider>(context).scheduledProgramPayload;
    final conditionPayload = Provider.of<MqttPayloadProvider>(context, listen: false).conditionPayload;

    if (spLive.isNotEmpty) {
      ProgramUpdater.updateProgramsFromMqtt(spLive, widget.scheduledPrograms, conditionPayload);
    }

    var filteredScheduleProgram = widget.currentLineSNo == 0 ? widget.scheduledPrograms :
    widget.scheduledPrograms.where((program) {
      final irrigationLine = program.irrigationLine;
      return irrigationLine.contains(widget.currentLineSNo) || irrigationLine.isEmpty;
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 3, bottom: 3),
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
                      color: Colors.grey.shade400,
                      width: 0.5,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                  height: (filteredScheduleProgram.length * 45) + 45,
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 1000,
                      dataRowHeight: 45,
                      headingRowHeight: 40,
                      headingRowColor: WidgetStateProperty.all(Colors.yellow.shade50),
                      columns: ProgramTableHelper.columns(context, ScheduledProgramWide.headerStyle,
                          widget.prgOnOffPermission, isNova),
                      rows: ProgramTableHelper.rows(
                        programs: filteredScheduleProgram,
                        context: context,
                        aiService: aiService,
                        currentLineSNo: widget.currentLineSNo,
                        showConditionDialog: showConditionDialog,
                        userId: widget.userId,
                        customerId: widget.customerId,
                        deviceId: widget.deviceId,
                        controllerId: widget.controllerId,
                        groupId: widget.groupId,
                        modelId: widget.modelId,
                        categoryId: widget.categoryId,
                        prgOnOffPermission: widget.prgOnOffPermission,
                        isNova: isNova,
                      ),
                    ),
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
                      color: Colors.yellow.shade100,
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                      border: Border.all(width: 0.5, color: Colors.black26)
                  ),
                  child: const Text('SCHEDULED PROGRAM',  style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showConditionDialog(
      BuildContext context,
      String prgName,
      List<ConditionModel> conditions,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                conditions.length > 1
                    ? 'Conditions of $prgName'
                    : 'Condition of $prgName',
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
                          color: cond.conditionStatus == 1
                              ? Colors.green
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        cond.value.rule,
                        style: TextStyle(
                          color: cond.conditionStatus == 1
                              ? Colors.green.shade700
                              : Colors.black54,
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