import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/widgets/periodicCard.dart';

import '../view/weather_screen_new.dart';
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
      return  RainfallCard(
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
      );
    }

    return Column(
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _sensorStatusColor(statusCode),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusCode == 255 ? 'Normal' : 'Alert',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

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

        const SizedBox(height: 20),

        SensorPeriodCard(
          title: 'Current Day',
          minValue: minValue.toString(),
          maxValue: maxValue.toString(),
          averageValue: otherValue,
        ),
        const SizedBox(height: 10),

        SensorPeriodCard(
          title: 'Last 7 Days',
          minValue: last7DaysMin.toString(),
          maxValue: last7DaysMax.toString(),
          averageValue: last7DaysAverage.toString(),
        ),
        const SizedBox(height: 10),

        SensorPeriodCard(
          title: 'Last Month',
          minValue: last30DaysMin.toString(),
          maxValue: last30DaysMax.toString(),
          averageValue: last30DaysAverage.toString(),
        ),
      ],
    );
  }
}