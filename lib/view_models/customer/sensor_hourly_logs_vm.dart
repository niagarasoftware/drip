
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer/site_model.dart';
import '../../repository/repository.dart';

class SensorHourlyLogsVm extends ChangeNotifier {
  final Repository repository;
  final int customerId;
  final int controllerId;
  final List<ConfigObject> configObjects;

  bool isLoading = false;
  String errorMessage = '';

  final Map<String, List<SensorHourlyData>> sensorsBySNo = {};

  DateTime selectedDate = DateTime.now();

  SensorHourlyLogsVm(
      this.repository,
      this.customerId,
      this.controllerId,
      this.configObjects,
      );

  Future<void> getSensorHourlyLogs([DateTime? date]) async {
    // Use the requested date, or the currently selected date.
    final requestedDate = date ?? selectedDate;
    selectedDate = requestedDate;

    final formattedDate = DateFormat('yyyy-MM-dd').format(requestedDate);

    // Clear old chart data immediately.
    sensorsBySNo.clear();
    errorMessage = '';
    isLoading = true;
    notifyListeners();

    try {
      final Map<String, Object> body = {
        'userId': customerId,
        'controllerId': controllerId,
        'fromDate': formattedDate,
        'toDate': formattedDate,
      };

      final response = await repository.fetchSensorHourlyData(body);

      if (response.statusCode != 200) {
        errorMessage = 'Failed to load sensor logs.';
        return;
      }

      final data = jsonDecode(response.body);

      if (data['code'] != 200) {
        errorMessage = data['message']?.toString() ??
            'Unable to load sensor logs.';
        return;
      }

      final jsonData = data['data'] as List;

      if (jsonData.isEmpty) {
        // Keep the charts empty for dates without data.
        return;
      }

      for (final hourEntry in jsonData[0].entries) {
        final String hour = hourEntry.key;
        final dynamic value = hourEntry.value;

        if (hour == 'date' || value == null || value.toString().isEmpty) {
          continue;
        }

        final sensorStrings = value.toString().split(';');

        for (final sensorStr in sensorStrings) {
          final parts = sensorStr.split(',');

          if (parts.length != 3) continue;

          final double? sNo = double.tryParse(parts[0].trim());
          if (sNo == null) continue;

          final double val1 = double.tryParse(parts[1].trim()) ?? 0.0;

          // Avoid firstWhere throwing if a sensor is missing in config.
          final int matchedIndex =
          configObjects.indexWhere((obj) => obj.sNo == sNo);

          if (matchedIndex == -1) continue;

          final matchedNode = configObjects[matchedIndex];

          final sensorData = SensorHourlyData(
            sNo: sNo,
            hour: hour,
            objectName: matchedNode.objectName,
            value: val1,
            name: matchedNode.name,
          );

          sensorsBySNo.putIfAbsent(sNo.toString(), () => []);
          sensorsBySNo[sNo.toString()]!.add(sensorData);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading hourly sensor logs: $e');
      debugPrintStack(stackTrace: stackTrace);
      errorMessage = 'An error occurred while loading sensor logs.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    // Compare calendar dates, not timestamps.
    final bool sameDate =
        picked.year == selectedDate.year &&
            picked.month == selectedDate.month &&
            picked.day == selectedDate.day;

    if (sameDate) return;

    selectedDate = picked;
    notifyListeners();

    await getSensorHourlyLogs(picked);
  }
}

class SensorHourlyData {
  final double sNo;
  final String? name;
  final String objectName;
  final double? value;
  final String hour;

  SensorHourlyData({
    required this.objectName,
    required this.value,
    required this.hour,
    required this.name,
    required this.sNo,
  });

  factory SensorHourlyData.fromJson(Map<String, dynamic> json) {
    String sensorName;

    if (json['Valve'] == null || json['Valve'].toString().isEmpty) {
      sensorName = '${json['Name'] ?? json['Id']}';
    } else {
      sensorName = '${json['Name'] ?? json['Id']}(${json['Valve']})';
    }

    return SensorHourlyData(
      sNo: (json['SNo'] as num).toDouble(),
      name: sensorName,
      objectName: json['objectName'] as String,
      value: json['Value'] is num
          ? (json['Value'] as num).toDouble()
          : double.tryParse(json['Value'].toString()) ?? 0.0,
      hour: json['hour'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'objectName': objectName,
      'Value': value,
      'hour': hour,
      'sNo': sNo,
    };
  }
}
