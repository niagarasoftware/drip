import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/customer/site_model.dart';
import '../../../StateManagement/mqtt_payload_provider.dart';

class NextSchedule extends StatelessWidget {
  const NextSchedule({super.key, required this.scheduledPrograms});
  final List<ProgramList> scheduledPrograms;

  @override
  Widget build(BuildContext context) {

    var nextSchedule =  context.watch<MqttPayloadProvider>().nextSchedule;

    return nextSchedule.isNotEmpty && nextSchedule[0].isNotEmpty ?
    Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
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
                  height:(nextSchedule.length * 45) + 50,
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 1000,
                      dataRowHeight: 45.0,
                      headingRowHeight: 40.0,
                      headingRowColor: WidgetStateProperty.all<Color>(Colors.orange.shade50),
                      columns: const [
                        DataColumn2(
                            label: Text('Name', style: TextStyle(fontSize: 13),),
                            size: ColumnSize.L
                        ),
                        DataColumn2(
                            label: Text('Method', style: TextStyle(fontSize: 13)),
                            size: ColumnSize.M

                        ),
                        DataColumn2(
                            label: Text('Location', style: TextStyle(fontSize: 13),),
                            size: ColumnSize.M
                        ),
                        DataColumn2(
                            label: Center(child: Text('Zone', style: TextStyle(fontSize: 13),)),
                            size: ColumnSize.S
                        ),
                        DataColumn2(
                            label: Center(child: Text('Zone Name', style: TextStyle(fontSize: 13),)),
                            size: ColumnSize.M
                        ),
                        DataColumn2(
                            label: Center(child: Text('Start Time', style: TextStyle(fontSize: 13),)),
                            size: ColumnSize.M
                        ),
                        DataColumn2(
                            label: Center(child: Text('Set(Duration/Flow)', style: TextStyle(fontSize: 13),)),
                            size: ColumnSize.M
                        ),
                      ],
                      rows: List<DataRow>.generate(nextSchedule.length, (index) {

                        List<String> values = nextSchedule[index].split(",");

                        return DataRow(cells: [
                          DataCell(Text(getProgramNameById(int.parse(values[0])))),
                          DataCell(Text(scheduledPrograms[index].selectedSchedule, style: const TextStyle(fontSize: 11),)),
                          const DataCell(Text('--')),
                          DataCell(Center(child: Text(values[7]))),
                          DataCell(Center(child: Center(child: Text(getSequenceName(int.parse(values[0]), values[1]) ?? '--')))),
                          DataCell(Center(child: Text(convert24HourTo12Hour(values[6])))),
                          DataCell(Center(child: Text(values[3]))),
                        ]);
                      }),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 5,
                left: 0,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade200,
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                      border: Border.all(width: 0.5, color: Colors.grey)
                  ),
                  child: const Text('NEXT SCHEDULE IN QUEUE',  style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    ) :
    const SizedBox();
  }

  String getProgramNameById(int id) {
    try {
      return scheduledPrograms.firstWhere((program) => program.serialNumber == id).programName;
    } catch (e) {
      return "Stand Alone";
    }
  }


  String? getSequenceName(int programId, String sequenceId) {
    ProgramList? program = getProgramById(programId);
    if (program != null) {
      return getSequenceNameById(program, sequenceId);
    }
    return null;
  }

  ProgramList? getProgramById(int id) {
    try {
      return scheduledPrograms.firstWhere((program) => program.serialNumber == id);
    } catch (e) {
      return null;
    }
  }

  String? getSequenceNameById(ProgramList program, String sequenceId) {
    try {
      return program.sequence.firstWhere((seq) => seq.sNo == sequenceId).name;
    } catch (e) {
      return null;
    }
  }

  String convert24HourTo12Hour(String timeString) {
    if(timeString=='-'){
      return '-';
    }
    final parsedTime = DateFormat('HH:mm:ss').parse(timeString);
    final formattedTime = DateFormat('hh:mm a').format(parsedTime);
    return formattedTime;
  }

}

String? getSequenceNameById(ProgramList program, String sequenceId) {
  try {
    return program.sequence.firstWhere((seq) => seq.sNo == sequenceId).name;
  } catch (e) {
    return null;
  }
}

String convert24HourTo12Hour(String timeString) {
  if(timeString=='-'){
    return '-';
  }
  final parsedTime = DateFormat('HH:mm:ss').parse(timeString);
  final formattedTime = DateFormat('hh:mm a').format(parsedTime);
  return formattedTime;
}