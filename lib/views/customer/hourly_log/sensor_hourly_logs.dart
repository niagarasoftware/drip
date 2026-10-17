
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../models/customer/site_model.dart';
import '../../../repository/repository.dart';
import '../../../services/http_service.dart';
import '../../../utils/my_function.dart';
import '../../../view_models/customer/sensor_hourly_logs_vm.dart';

class SensorHourlyLogs extends StatelessWidget {
  const SensorHourlyLogs({
    super.key,
    required this.userId,
    required this.controllerId,
    required this.configObjects,
  });

  final int userId;
  final int controllerId;
  final List<ConfigObject> configObjects;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SensorHourlyLogsVm(
        Repository(HttpService()),
        userId,
        controllerId,
        configObjects,
      )..getSensorHourlyLogs(),
      child: Consumer<SensorHourlyLogsVm>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Hourly Sensor logs'),
              actions: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      DateFormat('yyyy-MM-dd')
                          .format(viewModel.selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: viewModel.isLoading
                        ? null
                        : () => viewModel.selectDate(context),
                  ),
                ),
              ],
            ),
            body: viewModel.isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : viewModel.sensorsBySNo.isEmpty
                ? Center(
              child: Text(
                viewModel.errorMessage.isNotEmpty
                    ? viewModel.errorMessage
                    : 'No sensor logs available for '
                    '${DateFormat('yyyy-MM-dd').format(viewModel.selectedDate)}',
              ),
            )
                : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: viewModel.sensorsBySNo.entries.map((entry) {
                  final List<SensorHourlyData> chartData =
                      entry.value;

                  if (chartData.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return SfCartesianChart(
                    primaryXAxis: const CategoryAxis(),
                    title: ChartTitle(
                      text:
                      'Sensor Name: ${chartData.first.name}',
                    ),
                    legend: const Legend(isVisible: true),
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(
                        text: MyFunction().getSensorUnit(
                          chartData.first.objectName,
                          context,
                        ),
                      ),
                    ),
                    series: <LineSeries<SensorHourlyData, String>>[
                      LineSeries<SensorHourlyData, String>(
                        dataSource: chartData,
                        xValueMapper: (data, _) => data.hour,
                        yValueMapper: (data, _) =>
                            MyFunction().getChartValue(
                              context,
                              data.objectName,
                              data.value ?? 0.0,
                            ),
                        dataLabelSettings:
                        const DataLabelSettings(
                          isVisible: true,
                        ),
                        name: chartData.first.objectName,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}