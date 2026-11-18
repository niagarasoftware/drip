import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../model/chart_data_model.dart';
import '../model/event_log_model.dart';

class MotorLogChart extends StatelessWidget {
  final List<EventLog> motor1Logs;
  final List<EventLog> motor2Logs;
  final List<EventLog> motor3Logs;

  const MotorLogChart({super.key, required this.motor1Logs, required this.motor2Logs, required this.motor3Logs});

  @override
  Widget build(BuildContext context) {
    List<ChartData> motor1Data = getChartData(motor1Logs);
    List<ChartData> motor2Data = getChartData(motor2Logs);
    List<ChartData> motor3Data = getChartData(motor3Logs);

    return Scaffold(
      appBar: AppBar(title: const Text('Motor Logs')),
      body: SfCartesianChart(
        title: const ChartTitle(text: 'Motor Logs'),
        legend: const Legend(isVisible: true, position: LegendPosition.bottom),
        primaryXAxis: const DateTimeAxis(title: AxisTitle(text: 'Time')),
        primaryYAxis: const NumericAxis(title: AxisTitle(text: 'Event Count')),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: [
          BarSeries<ChartData, DateTime>(
            name: 'Motor 1',
            dataSource: motor1Data,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.value,
            dataLabelMapper: (ChartData data, _) => data.event,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            color: Colors.blue,
          ),
          BarSeries<ChartData, DateTime>(
            name: 'Motor 2',
            dataSource: motor2Data,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.value,
            dataLabelMapper: (ChartData data, _) => data.event,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            color: Colors.orange,
          ),
          BarSeries<ChartData, DateTime>(
            name: 'Motor 3',
            dataSource: motor3Data,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.value,
            dataLabelMapper: (ChartData data, _) => data.event,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  List<ChartData> getChartData(List<EventLog> logs) {
    List<ChartData> chartData = [];
    for (var log in logs) {
      DateTime onTime = DateTime.parse(log.onTime);
      DateTime offTime = DateTime.parse(log.offTime);
      // Duration duration = DateTime.parse(log.onTime);

      chartData.add(ChartData(onTime, 'On', 1));
      chartData.add(ChartData(offTime, 'Off', 1));
      // chartData.add(ChartData(onTime.add(duration), 'Duration', 1));
    }
    return chartData;
  }
}