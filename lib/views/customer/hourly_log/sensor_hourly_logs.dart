
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

                  return SizedBox(
                    height: 320,
                    child: SfCartesianChart(
                      // Touch the line -> shows hour + value for the nearest point
                      trackballBehavior: TrackballBehavior(
                        enable: true,
                        activationMode: ActivationMode.singleTap, // or longPress
                        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
                        lineType: TrackballLineType.vertical,
                        tooltipSettings: const InteractiveTooltip(
                          enable: true,
                          format: 'point.x : point.y',
                        ),
                      ),

                      // Pinch to zoom, drag to scroll when there are many points
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePinching: true,
                        enablePanning: true,
                        zoomMode: ZoomMode.x,
                      ),

                      primaryXAxis: const CategoryAxis(
                        interval: 1,                 // show every hour label
                        labelRotation: 90,           // avoids overlapping text
                        labelIntersectAction: AxisLabelIntersectAction.rotate90,
                        majorGridLines: MajorGridLines(width: 0),
                        // show ~10 points at a time, rest by panning
                        initialVisibleMaximum: 9,
                      ),

                      title: ChartTitle(text: 'Sensor Name: ${chartData.first.name}'),
                      legend: const Legend(isVisible: true),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(
                          text: MyFunction().getSensorUnit(chartData.first.objectName, context),
                        ),
                      ),

                      series: <LineSeries<SensorHourlyData, String>>[
                        LineSeries<SensorHourlyData, String>(
                          dataSource: chartData,
                          xValueMapper: (data, _) => data.hour,
                          yValueMapper: (data, _) => MyFunction().getChartValue(
                            context,
                            data.objectName,
                            data.value ?? 0.0,
                          ),
                          name: chartData.first.objectName,

                          // Show a dot on every point so you can see where data exists
                          markerSettings: const MarkerSettings(isVisible: true),

                          // Turn OFF always-on labels (they clutter with many points)
                          dataLabelSettings: const DataLabelSettings(isVisible: false),
                        ),
                      ],
                    ),
                  );

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