import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/view/weather_Gsm.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/widgets/sensor_tile_new.dart';

class SensorChipGsm extends StatelessWidget {
  final SensorDisplayModel device;
  final bool isNarrow;

  const SensorChipGsm({
    super.key,
    required this.device,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SensorTileNew(
        icon: Icons.sensors,
        title: device.name,
        statusCode: device.status,
        value: device.value,
        unit: _unit(device.name),

        // Current day
        minValue: device.min,
        maxValue: device.max,
        otherValue: device.average.toString(),

        // Last 7 days
        last7DaysMin: device.last7DaysMin,
        last7DaysMax: device.last7DaysMax,
        last7DaysAverage: device.last7DaysAverage,

        // Last 30 days
        last30DaysMin: device.last30DaysMin,
        last30DaysMax: device.last30DaysMax,
        last30DaysAverage: device.last30DaysAverage,
      ),
    );
  }

  String _unit(String type) {
    final name = type.toLowerCase();

    if (name.contains('moisture')) return 'CB';
    if (name.contains('temperature')) return '°C';
    if (name.contains('humidity')) return '%';
    if (name.contains('co2')) return 'ppm';
    if (name.contains('direction')) return '°';
    if (name.contains('wind')) return 'km/h';
    if (name.contains('rain')) return 'mm';
    if (name.contains('lux')) return 'Lu';
    if (name.contains('ldr')) return 'Ω';
    if (name.contains('leaf')) return '%';

    return '';
  }
}