import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/view_models/create_account_view_model.dart';
import 'package:provider/provider.dart';
import '../StateManagement/mqtt_payload_provider.dart';
import '../models/customer/site_model.dart';
import 'enums.dart';

class MyFunction {

  String? getUnitByParameter(BuildContext context, String parameter, String value) {
    MqttPayloadProvider payloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);

    try {
      Map<String, dynamic>? unitMap = payloadProvider.unitList.firstWhereOrNull(
            (unit) => unit['parameter'] == parameter,
      );

      if (unitMap == null) return '';

      double parsedValue = double.tryParse(value) ?? 0.0;

      if (parameter == 'Level Sensor') {
        switch (unitMap['value']) {
          case 'm':
            return 'meter: $value';
          case 'feet':
            return '${convertMetersToFeet(parsedValue).toStringAsFixed(2)} feet';
          default:
            return '${convertMetersToInches(parsedValue).toStringAsFixed(2)} inches';
        }
      }
      else if (unitMap['parameter'] == 'Pressure Sensor') {
        double barValue = double.tryParse(value) ?? 0.0;
        if (unitMap['value'] == 'bar') {
          return '$value ${unitMap['value']}';
        } else if (unitMap['value'] == 'kPa') {
          double convertedValue = convertBarToKPa(barValue);
          return '${convertedValue.toStringAsFixed(2)} kPa';
        }
      }
      else if (unitMap['parameter'] == 'Moisture Sensor') {
        return '$value ${unitMap['value']}';
      }
      else if (parameter == 'Water Meter') {
        double lps = parsedValue;
        switch (unitMap['value']) {
          case 'l/s':
            return '$value l/s';
          case 'l/h':
            return '${(lps * 3600).toStringAsFixed(2)} l/h';
          case 'm3/h':
            return '${(lps *3.6).toStringAsFixed(2)} m³/h';
          default:
            return '$value l/s';
        }
      }
      return '$parsedValue ${unitMap['value']}';
    } catch (e) {
      print('Error: $e');
      return 'Error: $e';
    }
  }

  double getChartValue(
      BuildContext context,
      String parameter,
      double value,
      ) {
    final unit = getUnitValue(context, parameter, value.toString());

    double result = value;

    if (parameter == 'Level Sensor') {
      if (unit == 'feet') {
        result = convertMetersToFeet(value);
      } else if (unit == 'inch') {
        result = convertMetersToInches(value);
      }
    }
    else if (parameter == 'Pressure Sensor') {
      if (unit == 'kPa') {
        result = convertBarToKPa(value);
      }
    }
    else if (parameter == 'Water Meter') {
      if (unit == 'l/h') result = value * 3600;
      if (unit == 'm3/h') result = value * 3.6;
    }

    return _round2(result);
  }

  double _round2(double v) => (v * 100).roundToDouble() / 100;


  String getSensorUnit(String type, BuildContext context) {
    if(type.contains('Moisture')||type.contains('SM')){
      return 'Values in Cb';
    }
    else if(type.contains('Pressure')){
      return 'Values in bar';
    }
    else if(type.contains('Level')){
      MqttPayloadProvider payloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);
      Map<String, dynamic>? unitMap = payloadProvider.unitList.firstWhereOrNull(
            (unit) => unit['parameter'] == 'Level Sensor',
      );
      if (unitMap == null) return '';
      return 'Values in ${unitMap['value']}';
    }
    else if(type.contains('Humidity')){
      return 'Percentage (%)';
    }
    else if(type.contains('Co2')){
      return 'Parts per million(ppm)';
    }else if(type.contains('Temperature')){
      return 'Celsius (°C)';
    }else if(type.contains('EC')||type.contains('PH')){
      return 'Siemens per meter (S/m)';
    }else if(type.contains('Power')){
      return 'Volts';
    }else if(type.contains('Water')){
      return 'Cubic Meters (m³)';
    }else{
      return 'Sensor value';
    }
  }

  String? getUnitValue(BuildContext context, String parameter, String value) {
    MqttPayloadProvider payloadProvider = Provider.of<MqttPayloadProvider>(context, listen: false);

    try {
      Map<String, dynamic>? unitMap = payloadProvider.unitList.firstWhereOrNull(
            (unit) => unit['parameter'] == parameter,
      );
      if (unitMap == null) return '';
      return unitMap['value'];
    } catch (e) {
      print('Error: $e');
      return 'Error: $e';
    }
  }

  double convertMetersToFeet(double meters) {
    return meters * 3.28084;
  }

  double convertMetersToInches(double meters) {
    return meters * 39.3701;
  }

  double convertBarToKPa(double bar) {
    return bar * 100;
  }

  String getAlarmMessage(int alarmType) {
    String msg = '';
    switch (alarmType) {
      case 1:
        msg ='Low Flow';
        break;
      case 2:
        msg ='High Flow';
        break;
      case 3:
        msg ='No Flow';
        break;
      case 4:
        msg ='Ec High';
        break;
      case 5:
        msg ='Ph Low';
        break;
      case 6:
        msg ='Ph High';
        break;
      case 7:
        msg ='Pressure Low';
        break;
      case 8:
        msg ='Pressure High';
        break;
      case 9:
        msg ='No Power Supply';
        break;
      case 10:
        msg ='No Communication';
        break;
      case 11:
        msg ='Wrong Feedback';
        break;
      case 12:
        msg ='Sump Tank Empty';
        break;
      case 13:
        msg ='Top Tank Full';
        break;
      case 14:
        msg ='Low Battery';
        break;
      case 15:
        msg ='Ec Difference';
        break;
      case 16:
        msg ='Ph Difference';
        break;
      case 17:
        msg ='Pump Off Alarm';
        break;
      case 18:
        msg ='Pressure Switch high';
        break;
      default:
        msg ='alarmType default';
    }
    return msg;
  }

  Color getMoistureColor(List<Map<String, dynamic>> sensors) {
    if (sensors.isEmpty) return Colors.grey;

    final values = sensors
        .map((ms) => double.tryParse(ms['value']?.toString() ?? '0') ?? 0.0)
        .toList();

    if (values.isEmpty) return Colors.grey;

    final averageValue = values.reduce((a, b) => a + b) / values.length;

    if (averageValue < 55) {
      return Colors.green.shade200;
    } else if (averageValue <= 120) {
      return Colors.orange.shade200;
    } else {
      return Colors.red.shade200;
    }
  }

  //my spacial function--------------------------------------------------------------
  //---------------------------------------------------------------------------------
  Set<String> items = {};
  void addItem(String item) {
    items.add(item); // Set automatically handles uniqueness.
  }

  String getProgramNameById(int id, List<ProgramList> scheduledPrograms) {
    try {
      return scheduledPrograms.firstWhere((program) => program.serialNumber == id).programName;
    } catch (e) {
      return "StandAlone - Manual";
    }
  }

  ProgramList? getProgramById(int id, List<ProgramList> scheduledPrograms) {
    try {
      return scheduledPrograms.firstWhere((program) => program.serialNumber == id);
    } catch (e) {
      return null;
    }
  }

  String? getSequenceName(int programId, String sequenceId, List<ProgramList> scheduledPrograms) {
    ProgramList? program = getProgramById(programId, scheduledPrograms);
    if (program != null) {
      return getSequenceNameById(program, sequenceId);
    }
    return null;
  }

  String? getSequenceNameById(ProgramList program, String sequenceId) {
    try {
      return program.sequence.firstWhere((seq) => seq.sNo == sequenceId).name;
    } catch (e) {
      return null;
    }
  }

  String getContentByCode(int code) {
    return GemProgramStartStopReasonCode.fromCode(code).content;
  }

  String convert24HourTo12Hour(String timeString) {
    if(timeString=='-'){
      return '-';
    }
    final parsedTime = DateFormat('HH:mm:ss').parse(timeString);
    final formattedTime = DateFormat('hh:mm a').format(parsedTime);
    return formattedTime;
  }

}

class IrrigationParams {
  final String cropType;
  final String soilType;
  final String moistureLevel;
  final String weather;
  final String area;
  final String growthStage;
  final String temperature;
  final String humidity;
  final String windSpeed;
  final String windDirection;
  final String cloudCover;
  final String pressure;
  final String recentRainfall;
  final String irrigationMethod;

  IrrigationParams({
    required this.cropType,
    required this.soilType,
    required this.moistureLevel,
    required this.weather,
    required this.area,
    required this.growthStage,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.cloudCover,
    required this.pressure,
    required this.recentRainfall,
    required this.irrigationMethod,
  });

  // Converts to prompt string for AI
  String toPrompt() {
    return '''
Irrigation Program Details:

- Crop Type: $cropType
- Soil Type: $soilType
- Area: $area sq.m
- Growth Stage: $growthStage
- Irrigation Method: $irrigationMethod
- Moisture Level: $moistureLevel%
- Temperature: $temperature°C
- Humidity: $humidity%
- Wind Speed: $windSpeed km/h
- Wind Direction: $windDirection°
- Rain Forecast: $weather
- Recent Rainfall: $recentRainfall mm
- Cloud Cover: $cloudCover %
- Pressure: $pressure hPa

Based on this data, what percentage should I apply to the total irrigation durations of the program?

✅ Respond with:
1. A single number in percentage (e.g., "80%") on the first line.
2. A brief explanation (1–2 sentences) on why this percentage was chosen, considering weather, moisture, and crop type.
''';
  }

  @override
  bool operator ==(Object other) =>
      other is IrrigationParams &&
          cropType == other.cropType &&
          soilType == other.soilType &&
          moistureLevel == other.moistureLevel &&
          weather == other.weather &&
          area == other.area &&
          growthStage == other.growthStage &&
          temperature == other.temperature &&
          humidity == other.humidity &&
          windSpeed == other.windSpeed &&
          cloudCover == other.cloudCover &&
          pressure == other.pressure &&
          recentRainfall == other.recentRainfall &&
          irrigationMethod == other.irrigationMethod;

  @override
  int get hashCode =>
      cropType.hashCode ^
      soilType.hashCode ^
      moistureLevel.hashCode ^
      weather.hashCode ^
      area.hashCode ^
      growthStage.hashCode ^
      temperature.hashCode ^
      humidity.hashCode ^
      windSpeed.hashCode ^
      cloudCover.hashCode ^
      pressure.hashCode ^
      recentRainfall.hashCode ^
      irrigationMethod.hashCode;
}