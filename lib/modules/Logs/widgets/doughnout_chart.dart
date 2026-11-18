import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../Constants/constants.dart';
import '../model/motor_data.dart';
import '../model/pie_chart_model.dart';

class DoughnutChart extends StatelessWidget {
  final List<MotorData> chartData;
  final Duration totalPowerDuration;
  const DoughnutChart({super.key, required this.chartData, required this.totalPowerDuration});

  @override
  Widget build(BuildContext context) {

    List<PieChartData> pieChartData = chartData.map((motor) {
      Duration motorDuration = Constants.parseTime(motor.powerConsumed);
      double percentage = totalPowerDuration.inMilliseconds != 0 ? (motorDuration.inMilliseconds / totalPowerDuration.inMilliseconds) * 100 : 0;
      return PieChartData(motor.name, percentage, motor.powerConsumed, motor.color);
    }).toList();

    Duration totalMotorDuration = const Duration();
    for (var motor in chartData) {
      totalMotorDuration += Constants.parseTime(motor.powerConsumed);
      // print(totalMotorDuration);
    }
    Duration balancePowerDuration = totalPowerDuration - totalMotorDuration;
    double balancePercentage = totalPowerDuration.inMilliseconds != 0 ? (balancePowerDuration.inMilliseconds / totalPowerDuration.inMilliseconds) * 100 : 0;
    pieChartData.add(PieChartData('Rem', balancePercentage, balancePowerDuration.toString().split('.')[0], const Color(0xff15C0E6)));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // "${value.inHours.toString().padLeft(2, '0')}:${(value.inMinutes % 60).toString().padLeft(2, '0')}"
          Text("Total duration: ${totalPowerDuration.inHours.toString().padLeft(2, '0')}:${(totalPowerDuration.inMinutes % 60).toString().padLeft(2, '0')}"),
          SizedBox(
            height: 180,
            child: SfCircularChart(
              // annotations: <CircularChartAnnotation>[
              //   CircularChartAnnotation(
              //     widget: Text(
              //       '${pieChartData[0].percentage.toStringAsFixed(1)}%',
              //       style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              //     ),
              //   ),
              // ],
              series: <CircularSeries>[
                DoughnutSeries<PieChartData, String>(
                  dataSource: pieChartData,
                  xValueMapper: (PieChartData data, _) => data.name,
                  yValueMapper: (PieChartData data, _) => data.percentage,
                  dataLabelMapper: (PieChartData data, _) => '${data.name}: ${Constants.changeFormat(data.duration)}',
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    labelPosition: ChartDataLabelPosition.outside,
                    labelAlignment: ChartDataLabelAlignment.auto,
                  ),
                  pointColorMapper: (PieChartData data, _) => data.color,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}