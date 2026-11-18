import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SensorReportTable extends StatelessWidget {
  final List<SensorHourData> data;
  final double sensorSrNo;

  const SensorReportTable({
    super.key,
    required this.data,
    required this.sensorSrNo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
        MaterialStateProperty.all(Colors.grey.shade200),
        columns: const [
          DataColumn(label: Text('Hour')),
          DataColumn(label: Text('Sensor SrNo')),
          DataColumn(label: Text('Value')),
          DataColumn(label: Text('Error')),
        ],
        rows: data.map((e) {
          return DataRow(
            cells: [
              DataCell(Text(e.hour)),
              DataCell(Text(sensorSrNo.toString())),
              DataCell(Text(e.value.toStringAsFixed(2))),
              DataCell(
                Text(
                  e.error.toString(),
                  style: TextStyle(
                    color: e.error == 255
                        ? Colors.green
                        : e.error == -1
                        ? Colors.grey
                        : Colors.red,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class SensorHourData {
  final String hour;
  final double value;
  final int error;

  SensorHourData({
    required this.hour,
    required this.value,
    required this.error,
  });
}
