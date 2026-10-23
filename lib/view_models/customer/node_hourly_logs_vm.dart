
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/customer/site_model.dart';
import '../../repository/repository.dart';

class NodeHourlyLogsVm extends ChangeNotifier {
  final Repository repository;
  final int customerId;
  final int controllerId;
  final List<NodeListModel> nodeList;

  final Map<String, List<ChartDataLog>> nodeDataMap = {};

  DateTime selectedDate = DateTime.now();

  bool isLoading = false;
  String errorMessage = '';

  bool _isDisposed = false;
  int _requestId = 0;

  NodeHourlyLogsVm(
      this.repository,
      this.customerId,
      this.controllerId,
      this.nodeList,
      );

  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> getNodeLogs([DateTime? date]) async {
    if (_isDisposed) return;

    if (date != null) {
      selectedDate = date;
    }

    final int currentRequestId = ++_requestId;

    final String formattedDate =
    DateFormat('yyyy-MM-dd').format(selectedDate);

    // Clear old data immediately so the previous date is not displayed.
    nodeDataMap.clear();
    errorMessage = '';
    isLoading = true;
    safeNotify();

    try {
      final Map<String, Object> body = {
        'userId': customerId,
        'controllerId': controllerId,
        'fromDate': formattedDate,
        'toDate': formattedDate,
      };

      final response = await repository.fetchNodeHourlyData(body);

      // Ignore an old request if the selected date has changed again.
      if (_isDisposed || currentRequestId != _requestId) return;

      if (response.statusCode != 200) {
        errorMessage = 'Failed to load node hourly logs.';
        return;
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map || decoded['code'] != 200) {
        errorMessage = 'Unable to load node hourly logs.';
        return;
      }

      final dynamic responseData = decoded['data'];

      if (responseData is! List || responseData.isEmpty) {
        // No data for this date. The map remains empty.
        return;
      }

      final dynamic firstRecord = responseData.first;

      if (firstRecord is! Map) {
        errorMessage = 'Invalid node hourly log response.';
        return;
      }

      for (final entry in firstRecord.entries) {
        if (_isDisposed || currentRequestId != _requestId) return;

        final String hour = entry.key.toString();
        final dynamic rawValue = entry.value;

        if (hour == 'date' ||
            rawValue == null ||
            rawValue.toString().isEmpty) {
          continue;
        }

        final List<String> nodeStrings =
        rawValue.toString().split(';');

        for (final nodeStr in nodeStrings) {
          final List<String> parts = nodeStr.split(',');

          if (parts.length != 3) continue;

          final int? serialNumber =
          int.tryParse(parts[0].trim());

          if (serialNumber == null) continue;

          final double batteryVoltage =
              double.tryParse(parts[1].trim()) ?? 0.0;

          final double solarVoltage =
              double.tryParse(parts[2].trim()) ?? 0.0;

          final int matchedIndex = nodeList.indexWhere(
                (node) => node.serialNumber == serialNumber,
          );

          // Ignore nodes that are not present in the supplied node list.
          if (matchedIndex == -1) continue;

          final matchedNode = nodeList[matchedIndex];
          final String deviceId = matchedNode.deviceId;

          nodeDataMap.putIfAbsent(deviceId, () => []);

          nodeDataMap[deviceId]!.add(
            ChartDataLog(
              matchedNode.deviceName,
              hour,
              batteryVoltage,
              solarVoltage,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      if (!_isDisposed && currentRequestId == _requestId) {
        debugPrint('Error loading node hourly logs: $e');
        debugPrintStack(stackTrace: stackTrace);
        errorMessage = 'An error occurred while loading node logs.';
      }
    } finally {
      if (!_isDisposed && currentRequestId == _requestId) {
        isLoading = false;
        safeNotify();
      }
    }
  }

  Future<void> selectDate(BuildContext context) async {
    if (isLoading || _isDisposed) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null || _isDisposed) return;

    final bool sameDate =
        picked.year == selectedDate.year &&
            picked.month == selectedDate.month &&
            picked.day == selectedDate.day;

    if (sameDate) return;

    selectedDate = picked;
    safeNotify();

    await getNodeLogs(picked);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class ChartDataLog {
  final String deviceName;
  final String hour;
  final double batteryVoltage;
  final double solarVoltage;

  ChartDataLog(
      this.deviceName,
      this.hour,
      this.batteryVoltage,
      this.solarVoltage,
      );
}
