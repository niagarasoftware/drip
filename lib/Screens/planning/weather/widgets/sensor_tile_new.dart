import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/widgets/periodicCard.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/widgets/periodicCardCurrent.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/model/weather_model.dart';

import '../weather_co2_card.dart';
import '../weather_rainfall_card.dart';
import '../weather_wind_card.dart';

Color _sensorStatusColor(int code) {
  if (code == 255) return Colors.green.shade700;

  switch (code) {
    case 1:
      return Colors.red.shade700;
    case 2:
      return Colors.yellow.shade700;
    case 3:
      return Colors.orange.shade700;
    default:
      return Colors.grey.shade600;
  }
}

class SensorTileNew extends StatelessWidget {
  final IconData icon;
  final String title;
  final int statusCode;
  final double value;
  final String unit;

  // Current/live values
  final double minValue;
  final double maxValue;
  final String otherValue;
  final String? wetHours;

  // 7-day values
  final double last7DaysMin;
  final double last7DaysMax;
  final double last7DaysAverage;

  // 30-day values
  final double last30DaysMin;
  final double last30DaysMax;
  final double last30DaysAverage;

  const SensorTileNew({
    super.key,
    required this.icon,
    required this.title,
    required this.statusCode,
    required this.value,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.otherValue,
    this.wetHours,
    required this.last7DaysMin,
    required this.last7DaysMax,
    required this.last7DaysAverage,
    required this.last30DaysMin,
    required this.last30DaysMax,
    required this.last30DaysAverage,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedTitle = title.toLowerCase();

    if (normalizedTitle.contains('co2')) {
      return CO2Card(
        icon: icon,
        co2Value: value.toInt(),
        maxValue: 2000,
        title: title,
        message: '',
        min: minValue.toString(),
        max: maxValue.toString(),
        other: otherValue,
        last7DaysMin: last7DaysMin,
        last7DaysMax: last7DaysMax,
        last7DaysAverage: last7DaysAverage,
        last30DaysMin: last30DaysMin,
        last30DaysMax: last30DaysMax,
        last30DaysAverage: last30DaysAverage,
      );
    }

    if (normalizedTitle.contains('rain fall')) {
      return RainfallCard(
        icon: icon,
        rainfallValue: value.toString(),
        forecastText: '',
        description: '',
        min: minValue.toString(),
        max: maxValue.toString(),
        other: otherValue,
        last7DaysMin: last7DaysMin,
        last7DaysMax: last7DaysMax,
        last7DaysAverage: last7DaysAverage,
        last30DaysMin: last30DaysMin,
        last30DaysMax: last30DaysMax,
        last30DaysAverage: last30DaysAverage,
      );
    }

    if (normalizedTitle.contains('wind direction')) {
      return WindCard(
        icon: icon,
        directionAngle: value,
        statusCode: statusCode,
      );
    }

    final bool isLeafWetness = normalizedTitle.contains('leaf wetness');
    final String leafStatusText = isLeafWetness ? getLeafWetnessStatus(value) : '';
    final Color leafStatusColor = isLeafWetness ? getLeafWetnessStatusColor(value) : Colors.transparent;

    final String normalAlertText = statusCode == 255 ? 'Normal' : 'Alert';
    final Color normalAlertColor = _sensorStatusColor(statusCode);

    return SizedBox(
      height: 430,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 48),
              Text(
                normalAlertText,
                style: TextStyle(
                  color: normalAlertColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!isLeafWetness)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),

          if (isLeafWetness) ...[
            Text(
              leafStatusText,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: leafStatusColor,
                height: 1,
              ),
            ),
            if (wetHours != null && wetHours!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Wet Duration: $wetHours hrs',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ],

          const SizedBox(height: 14),

          SensorPeriodCardCurrent(
            title: 'Current Day',
            minValue: isLeafWetness ? getLeafWetnessStatus(minValue) : minValue.toString(),
            maxValue: isLeafWetness ? getLeafWetnessStatus(maxValue) : maxValue.toString(),
            averageValue: isLeafWetness ? getLeafWetnessStatus(double.tryParse(otherValue) ?? otherValue) : otherValue,
          ),
          const SizedBox(height: 8),

          SensorPeriodCard(
            title: 'Last 7 Days',
            minValue: isLeafWetness ? getLeafWetnessStatus(last7DaysMin) : last7DaysMin.toString(),
            maxValue: isLeafWetness ? getLeafWetnessStatus(last7DaysMax) : last7DaysMax.toString(),
            averageValue: isLeafWetness ? getLeafWetnessStatus(last7DaysAverage) : last7DaysAverage.toString(),
          ),
          const SizedBox(height: 8),

          SensorPeriodCard(
            title: 'Last Month',
            minValue: isLeafWetness ? getLeafWetnessStatus(last30DaysMin) : last30DaysMin.toString(),
            maxValue: isLeafWetness ? getLeafWetnessStatus(last30DaysMax) : last30DaysMax.toString(),
            averageValue: isLeafWetness ? getLeafWetnessStatus(last30DaysAverage) : last30DaysAverage.toString(),
          ),
        ],
      ),
    );
  }
}
