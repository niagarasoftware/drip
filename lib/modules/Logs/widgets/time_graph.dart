import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../model/time_data_model.dart';
class TimeGraph extends StatelessWidget {
  final List<TimeData> data;

  const TimeGraph({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('On Time, Off Time, and Duration')),
      body: SfCartesianChart(
        primaryXAxis: const CategoryAxis(),
        primaryYAxis: const NumericAxis(),
        series: [
          StackedBarSeries<TimeData, String>(
            dataSource: data,
            xValueMapper: (TimeData time, _) => time.label,
            yValueMapper: (TimeData time, _) => time.onTimeInMinutes,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
          StackedBarSeries<TimeData, String>(
            dataSource: data,
            xValueMapper: (TimeData time, _) => time.label,
            yValueMapper: (TimeData time, _) => time.offTimeInMinutes,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
          StackedBarSeries<TimeData, String>(
            dataSource: data,
            xValueMapper: (TimeData time, _) => time.label,
            yValueMapper: (TimeData time, _) => time.onTimeInMinutes + time.durationInMinutes,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  List<TimeData> getTimeData() {
    return [
      TimeData(label: 'Event 1', onTime: DateTime(2024, 8, 1, 8, 0), offTime: DateTime(2024, 8, 1, 10, 0), duration: const Duration(hours: 2)),
      TimeData(label: 'Event 2', onTime: DateTime(2024, 8, 1, 11, 0), offTime: DateTime(2024, 8, 1, 14, 0), duration: const Duration(hours: 3)),
      TimeData(label: 'Event 3', onTime: DateTime(2024, 8, 1, 15, 0), offTime: DateTime(2024, 8, 1, 17, 0), duration: const Duration(hours: 2)),
    ];
  }
}