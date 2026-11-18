import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../models/customer/sensor_hourly_data_model.dart';
import '../../../../models/customer/site_model.dart';
import '../../../../repository/repository.dart';
import '../../../../services/http_service.dart';

class SensorPopoverContent extends StatefulWidget {
  final SensorModel sensor;
  final String sensorType;
  final int customerId, controllerId;

  const SensorPopoverContent({
    super.key,
    required this.sensor,
    required this.sensorType,
    required this.customerId,
    required this.controllerId,
  });

  @override
  State<SensorPopoverContent> createState() => _SensorPopoverContentState();
}

class _SensorPopoverContentState extends State<SensorPopoverContent> {
  DateTime selectedDate = DateTime.now();
  List<SensorHourlyData> filteredData = [];

  @override
  void initState() {
    super.initState();
    _filterDataByDate();
  }

  Future<List<SensorHourlyDataModel>> fetchSensorData(DateTime fromDate, DateTime toDate) async {
    List<SensorHourlyDataModel> sensors = [];

    try {
      final from = DateFormat('yyyy-MM-dd').format(fromDate);
      final to = DateFormat('yyyy-MM-dd').format(toDate);

      final body = {
        "userId": widget.customerId,
        "controllerId": widget.controllerId,
        "fromDate": from,
        "toDate": to,
      };

      final response = await Repository(HttpService()).fetchSensorHourlyData(body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData["code"] == 200) {
          sensors = (jsonData['data'] as List).map((item) {
            final dateStr = item['date'];
            final Map<String, List<SensorHourlyData>> hourlyDataMap = {};

            item.forEach((key, value) {
              if (key == 'date') return;
              if (value is String && value.isNotEmpty) {
                final entries = value.split(';');
                hourlyDataMap[key] = entries
                    .map((entry) => SensorHourlyData.fromCsv(entry, key, dateStr))
                    .toList();
              } else {
                hourlyDataMap[key] = [];
              }
            });

            return SensorHourlyDataModel(date: dateStr, data: hourlyDataMap);
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching sensor hourly data: $e');
    }

    return sensors;
  }

  List<SensorHourlyData> getSensorDataById(String sensorId, List<SensorHourlyDataModel> sensorData) {
    final result = <SensorHourlyData>[];
    for (final model in sensorData) {
      model.data.forEach((_, sensorList) {
        result.addAll(sensorList.where((sensor) => sensor.sensorId == sensorId));
      });
    }
    return result;
  }

  Future<void> _filterDataByDate() async {

    final sensors = await fetchSensorData(selectedDate, selectedDate);
    final sensorDataList = getSensorDataById(widget.sensor.sNo.toString(), sensors);

    setState(() {
      filteredData = sensorDataList
          .where((data) => isSameDate(data.date, selectedDate))
          .toList();
    });
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildGauge(),
            Expanded(child: buildCommonCalendar(context)),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: double.infinity,
          height: 175,
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(
              title: AxisTitle(text: '${widget.sensor.name} - Hours'),
            ),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: [
              LineSeries<SensorHourlyData, String>(
                dataSource: filteredData,
                xValueMapper: (d, _) => d.hour,
                yValueMapper: (d, _) => double.tryParse(d.value) ?? 0,
                markerSettings: const MarkerSettings(isVisible: true),
                color: Theme.of(context).primaryColorLight,
                name: widget.sensor.name,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGauge() {
    final max = widget.sensorType == 'Moisture Sensor' ? 200
        : widget.sensorType == 'Pressure Sensor' ? 12
        : 100;

    return SizedBox(
      width: 100,
      height: 100,
      child: SfRadialGauge(
        axes: [
          RadialAxis(
            minimum: 0,
            maximum: max.toDouble(),
            pointers: [
              NeedlePointer(
                value: double.tryParse(widget.sensor.value) ?? 0,
                needleEndWidth: 3,
                needleColor: Colors.black54,
              ),
              const RangePointer(
                value: 200.0,
                width: 0.30,
                sizeUnit: GaugeSizeUnit.factor,
                color: Color(0xFF494CA2),
                animationDuration: 1000,
                gradient: SweepGradient(
                  colors: <Color>[
                    Colors.tealAccent,
                    Colors.orangeAccent,
                    Colors.redAccent,
                    Colors.redAccent,
                  ],
                  stops: <double>[0.15, 0.50, 0.70, 1.00],
                ),
                enableAnimation: true,
              ),
            ],
            annotations: [
              GaugeAnnotation(
                widget: Text(
                  widget.sensor.value,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                angle: 90,
                positionFactor: 0.8,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildCommonCalendar(BuildContext context) {
    return TableCalendar(
      focusedDay: selectedDate,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      calendarFormat: CalendarFormat.week,
      availableCalendarFormats: const {
        CalendarFormat.week: 'Week',
      },
      selectedDayPredicate: (day) => isSameDate(day, selectedDate),
      onDaySelected: (selectedDay, focusedDay) {
        selectedDate = selectedDay;
        _filterDataByDate();
      },
      enabledDayPredicate: (day) => !day.isAfter(DateTime.now()),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(color: Colors.white),
        todayTextStyle: const TextStyle(color: Colors.black),
      ),
    );
  }
}