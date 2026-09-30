import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/widgets/sensor_tile_new.dart';

import '../model/weather_model.dart';
import '../view_model/weather_view_model.dart';

class SensorChip extends StatelessWidget {
  final ConfigObjectNew sensor;
  final WeatherViewModel vm;
  final WeatherDeviceList device;
  final bool isNarrow;

  const SensorChip({
    super.key,
    required this.sensor,
    required this.vm,
    required this.device,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    final live = vm.getSensorLiveBySerial(
      serial: device.serialNumber,
      objectName: sensor.objectName,
      objectSno: sensor.sNo,
      controllerId: device.controllerId,
    );

    final model = vm.weatherModel;
    if (live == null || model == null) {
      return const SizedBox.shrink();
    }

    final last7Days = model.getLast7DaysStats(sensor.sNo);
    final last30Days = model.getLast30DaysStats(sensor.sNo);

    return Container(
      width: isNarrow ? double.infinity : 230,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SensorTileNew(
        icon: Icons.sensors,
        title: sensor.name,
        statusCode: live.status,
        value: live.value,
        unit: _unit(sensor.objectName),

        // Current/live values
        minValue: live.min,
        maxValue: live.max,
        otherValue: live.avg.toString(),

        // JSON last7Days values
        last7DaysMin: last7Days.min,
        last7DaysMax: last7Days.max,
        last7DaysAverage: last7Days.average,

        // JSON last30Days values
        last30DaysMin: last30Days.min,
        last30DaysMax: last30Days.max,
        last30DaysAverage: last30Days.average,
      ),
    );
  }

  String _unit(String type) {
    final normalizedType = type.toLowerCase();

    if (normalizedType.contains('moisture')) return 'CB';
    if (normalizedType.contains('temperature')) return '°C';
    if (normalizedType.contains('humidity')) return '%';
    if (normalizedType.contains('co2')) return 'ppm';
    if (normalizedType.contains('direction')) return '°';
    if (normalizedType.contains('wind')) return 'km/h';
    if (normalizedType.contains('rain')) return 'mm';
    if (normalizedType.contains('lux')) return 'Lu';

    return '';
  }
}