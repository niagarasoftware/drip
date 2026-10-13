import 'package:flutter/material.dart';
import '../model/weather_model.dart';
import '../view_model/weather_view_model.dart';
import 'reusable_sensor_card.dart';

class SensorChip extends StatelessWidget {
  final ConfigObjectNew sensor;
  final WeatherViewModel vm;
  final WeatherDeviceList device;
  final bool isNarrow;
  final VoidCallback? onLast7DaysTap;
  final VoidCallback? onLastMonthTap;

  const SensorChip({super.key, required this.sensor, required this.vm,
    required this.device, required this.isNarrow,
    this.onLast7DaysTap, this.onLastMonthTap});

  @override
  Widget build(BuildContext context) {
    final live = vm.getSensorLiveBySerial(
      serial: device.serialNumber,
      objectName: sensor.objectName,
      objectSno: sensor.sNo,
      controllerId: device.controllerId,
    );
    final model = vm.weatherModel;
    if (live == null || model == null) return const SizedBox.shrink();

    final week = model.getLast7DaysStats(sensor.sNo);
    final month = model.getLast30DaysStats(sensor.sNo);
    final type = '${sensor.objectName} ${sensor.name}'.toLowerCase();
    final isDirection = type.contains('direction');

    return ReusableSensorCard(
      title: sensor.name,
      icon: sensorIcon(type),
      accent: sensorAccent(type),
      unit: sensorUnit(type),
      value: live.value.toDouble(),
      statusCode: live.status,
      todayMin: live.min.toDouble(),
      todayMax: live.max.toDouble(),
      todayAverage: live.avg.toDouble(),
      weekAverage: week.average.toDouble(),
      monthAverage: month.average.toDouble(),
      isWindDirection: isDirection,
      onWeekTap: onLast7DaysTap,
      onMonthTap: onLastMonthTap,
    );
  }
}

String sensorUnit(String type) {
  type = type.toLowerCase();
  if (type.contains('moisture')) return 'CB';
  if (type.contains('temperature')) return '°C';
  if (type.contains('humidity') || type.contains('wetness')) return '%';
  if (type.contains('co2') || type.contains('co₂')) return 'ppm';
  if (type.contains('direction')) return '°';
  if (type.contains('wind')) return 'km/h';
  if (type.contains('rain')) return 'mm';
  if (type.contains('lux')) return 'Lu';
  return '';
}

IconData sensorIcon(String type) {
  if (type.contains('direction')) return Icons.explore_outlined;
  if (type.contains('moisture')) return Icons.grass;
  if (type.contains('temperature')) return Icons.thermostat;
  if (type.contains('humidity') || type.contains('wetness')) return Icons.water_drop_outlined;
  if (type.contains('wind')) return Icons.air;
  if (type.contains('rain')) return Icons.water_drop;
  if (type.contains('lux')) return Icons.wb_sunny_outlined;
  if (type.contains('co2')) return Icons.cloud_outlined;
  return Icons.sensors;
}

Color sensorAccent(String type) {
  if (type.contains('direction')) return const Color(0xFF7C3AED);
  if (type.contains('temperature')) return const Color(0xFFEA580C);
  if (type.contains('wind') || type.contains('rain')) return const Color(0xFF2563EB);
  if (type.contains('lux')) return const Color(0xFFE5A000);
  return const Color(0xFF159447);
}
