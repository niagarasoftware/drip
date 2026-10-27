import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../models/customer/site_model.dart';
import '../../../services/http_service.dart';
import '../../Logs/model/motor_data.dart';
import '../../Logs/model/motor_data_hourly.dart';
import '../../Logs/model/pump_log_data.dart';
import '../../Logs/repository/log_repos.dart';

class PumpControllerProvider extends ChangeNotifier {
  final LogRepository repository = LogRepository(HttpService());
  List<PumpLogData> pumpLogData = [];
  DateTime focusedDay = DateTime.now();
  Map<int, String> segments = {};
  String message = "";
  int selectedIndex = 0;
  CalendarFormat calendarFormat = CalendarFormat.week;
  final ScrollController scrollController = ScrollController();
  DateTime selectedDate = DateTime.now();

  List<DateTime> dates = List.generate(1, (index) => DateTime.now().subtract(Duration(days: index)));
  List<MotorDataHourly> motorDataList = [];
  List<PageController> pageController = [];
  List<MotorData> chartData = [];
  bool isLoading = false;

  List<Map<String, dynamic>> voltageData = [];

  /// Voltage feed has its own message so it can no longer clash with the pump-log message
  /// when both are fetched at the same time.
  String voltageMessage = "";

  /// Voltage feed has its own loading flag so other feeds can't switch its loader on/off.
  bool isVoltageLoading = false;

  /// Last time each feed was refreshed successfully (useful for a "Updated hh:mm:ss" label).
  DateTime? lastPumpLogSync;
  DateTime? lastHourlySync;
  DateTime? lastVoltageSync;

  // ---------------------------------------------------------------------------
  // Request tokens.
  // Every fetch takes a ticket. When the response arrives, it is applied only if
  // no newer fetch of the same kind has started. This stops a slow response for an
  // old date/device from overwriting the data for the one currently selected.
  // ---------------------------------------------------------------------------
  int _pumpLogTicket = 0;
  int _hourlyTicket = 0;
  int _voltageTicket = 0;

  static final DateFormat _apiDate = DateFormat("yyyy-MM-dd");

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  List<String> getPumpNames(MasterControllerModel? masterData, int nodeControllerId, int controllerId) {
    if (masterData != null) {
      final targetControllerId = nodeControllerId != 0 ? nodeControllerId : controllerId;

      var targetPumps = masterData.configObjects
          .where((e) => e.objectId == 5 && e.controllerId == targetControllerId)
          .toList();

      if (targetPumps.isEmpty && nodeControllerId == 0) {
        targetPumps = masterData.configObjects.where((e) => e.objectId == 5).toList();
      }

      if (targetPumps.isNotEmpty) {
        final List<String> names = [];
        for (var pump in targetPumps) {
          final name = pump.name.isNotEmpty ? pump.name : "Motor ${names.length + 1}";
          names.add(name);
        }
        return names;
      }

      if (nodeControllerId != 0) {
        final matchingNode =
            masterData.nodeList.where((n) => n.controllerId == nodeControllerId).firstOrNull;
        if (matchingNode != null && matchingNode.deviceName.isNotEmpty) {
          return [matchingNode.deviceName];
        }
      }
    }
    return ["Motor 1"];
  }

  /// Safe numeric parse. Returns null for null / "" / "-" / "NA" / "null" / NaN,
  /// so a missing reading is never confused with a real 0.
  static double? parseReading(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final d = value.toDouble();
      return d.isNaN || d.isInfinite ? null : d;
    }
    final s = value.toString().trim();
    if (s.isEmpty || s == '-' || s == '--' || s.toLowerCase() == 'null' || s.toLowerCase() == 'na') {
      return null;
    }
    final d = double.tryParse(s);
    if (d == null || d.isNaN || d.isInfinite) return null;
    return d;
  }

  static int? _parseHour(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  // ---------------------------------------------------------------------------
  // PUMP EVENT LOG   (api/v1/user/log/pump|nodePump/get)
  // ---------------------------------------------------------------------------
  /// [silent] = true is used by the auto-refresh: no loading flag, no artificial delay,
  /// the existing list stays on screen until the new one is ready, and the user's
  /// selected motor tab is preserved.
  Future<void> getUserPumpLog(userId, controllerId, nodeControllerId,
      [MasterControllerModel? masterData, bool silent = false]) async {
    final int ticket = ++_pumpLogTicket;
    final DateTime requestedDate = selectedDate;

    final Map<String, dynamic> data = {
      "userId": userId,
      "controllerId": controllerId,
      "nodeControllerId": nodeControllerId,
      "fromDate": _apiDate.format(requestedDate),
      "toDate": _apiDate.format(requestedDate),
    };

    try {
      if (!silent) {
        isLoading = true;
      }
      final res = await repository.getUserPumpLog(data, nodeControllerId != 0);
      if (ticket != _pumpLogTicket) return; // a newer request owns the state now

      final response = jsonDecode(res.body);

      // Build everything in locals first, swap in one go -> no half-cleared UI.
      List<PumpLogData> newLog = [];
      final Map<int, String> newSegments = {};
      String newMessage = "";
      int newSelectedIndex = 0;

      if (res.statusCode == 200) {
        if (response['data'] is List) {
          newLog = (response['data'] as List).map((i) => PumpLogData.fromJson(i)).toList();
          final pumpNames = getPumpNames(masterData, nodeControllerId, controllerId);

          int numPumps = pumpNames.length;
          for (final entry in newLog) {
            if (entry.motor3.isNotEmpty && numPumps < 3) {
              numPumps = 3;
            } else if (entry.motor2.isNotEmpty && numPumps < 2) {
              numPumps = 2;
            }
          }

          if (numPumps < 1) numPumps = 1;
          if (numPumps > 3) numPumps = 3;

          for (int i = 0; i < numPumps; i++) {
            newSegments[i] = (pumpNames.length > i && pumpNames[i].isNotEmpty)
                ? pumpNames[i]
                : "Motor ${i + 1}";
          }

          if (newSegments.containsKey(selectedIndex)) {
            newSelectedIndex = selectedIndex;
          } else if (newSegments.isNotEmpty) {
            newSelectedIndex = newSegments.keys.first;
          }
        } else {
          newMessage = '${response['message']}';
        }
      } else {
        newMessage = 'Failed to load data: ${response['message']}';
      }

      // Silent refresh keeps the motor tab the user is looking at (if it still exists).
      if (silent && newSegments.containsKey(selectedIndex)) {
        newSelectedIndex = selectedIndex;
      }

      final bool grew = newLog.isNotEmpty &&
          (pumpLogData.isEmpty || _eventCount(newLog) != _eventCount(pumpLogData));

      pumpLogData = newLog;
      segments
        ..clear()
        ..addAll(newSegments);
      selectedIndex = newSelectedIndex;
      message = newMessage;
      if (res.statusCode == 200 && response['data'] is List) lastPumpLogSync = DateTime.now();

      // Only auto-scroll when there is something new (otherwise polling would yank the list).
      if (grew && (!silent || _isSameDay(requestedDate, DateTime.now()))) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (e, stackTrace) {
      if (ticket != _pumpLogTicket) return;
      log("getUserPumpLog error: $e\n$stackTrace");
      if (!silent) message = 'Error occurred: $e';
    } finally {
      if (ticket == _pumpLogTicket) {
        if (!silent) isLoading = false;
        notifyListeners();
      }
    }
  }

  int _eventCount(List<PumpLogData> list) =>
      list.fold<int>(0, (s, e) => s + e.motor1.length + e.motor2.length + e.motor3.length);

  // ---------------------------------------------------------------------------
  // HOURLY / POWER GRAPH   (api/v1/user/log/pumpHourly|nodePumpHourly/get)
  // ---------------------------------------------------------------------------
  Future<void> getPumpControllerData({
    int selectedIndex = 0,
    required int userId,
    required int controllerId,
    required int nodeControllerId,
    bool silent = false,
  }) async {
    final int ticket = ++_hourlyTicket;

    if (selectedIndex == 1) {
      dates = List.generate(7, (index) => DateTime.now().subtract(Duration(days: index)));
    } else if (selectedIndex == 2) {
      dates = List.generate(30, (index) => DateTime.now().subtract(Duration(days: index)));
    } else if (selectedIndex == 0) {
      dates.last = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    } else {
      dates.last = DateTime.parse(dates.last.toString().split(' ')[0]);
    }

    final data = {
      "userId": userId,
      "controllerId": controllerId,
      "nodeControllerId": nodeControllerId,
      "fromDate": _apiDate.format(selectedIndex == 0 ? selectedDate : dates.last),
      "toDate": _apiDate.format(selectedIndex == 0 ? selectedDate : dates.first),
      "needSum": selectedIndex != 0
    };

    try {
      if (!silent) isLoading = true;
      final res = await repository.getUserPumpHourlyLog(data, nodeControllerId != 0);
      if (ticket != _hourlyTicket) return;

      final response = jsonDecode(res.body);

      List<MotorDataHourly> newList = [];
      final List<MotorData> newChart = [];

      if (res.statusCode == 200 && response['data'] is List) {
        newList = (response['data'] as List)
            .map((item) => MotorDataHourly.fromJson(item as Map<String, dynamic>))
            .toList();

        if (newList.isNotEmpty) {
          final first = newList[0];
          final colors = <Color>[
            Colors.lightBlueAccent.shade100.withOpacity(0.6),
            Colors.lightGreenAccent.withOpacity(0.6),
            Colors.greenAccent.withOpacity(0.6),
          ];
          final runTimes = [first.motorRunTime1, first.motorRunTime2, first.motorRunTime3];
          for (var i = 0; i < first.numberOfPumps && i < 3; i++) {
            newChart.add(MotorData("M${i + 1}", runTimes[i], colors[i]));
          }
        }
        lastHourlySync = DateTime.now();
      } else {
        log(res.statusCode == 200 ? 'Hourly data is not a List' : 'Failed to load hourly data');
      }

      motorDataList = newList;
      chartData = newChart;
    } catch (e, stackTrace) {
      if (ticket != _hourlyTicket) return;
      log("getPumpControllerData error: $e\n$stackTrace");
      // keep the last good data on a silent refresh; clear on an explicit load
      if (!silent) {
        motorDataList = [];
        chartData = [];
      }
    } finally {
      if (ticket == _hourlyTicket) {
        if (!silent) isLoading = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // VOLTAGE / CURRENT   (api/v1/user/log/pumpVoltage|nodePumpVoltage/get)
  // ---------------------------------------------------------------------------
  /// Callers must NOT call this synchronously from initState/didUpdateWidget/build
  /// (it notifies listeners immediately). Wrap in addPostFrameCallback there.
  Future<void> getUserVoltageLog({
    required int userId,
    required int controllerId,
    required int nodeControllerId,
    bool silent = false,
  }) async {
    final int ticket = ++_voltageTicket;
    final DateTime requestedDate = selectedDate;
    final String reqDateStr = _apiDate.format(requestedDate);

    final Map<String, dynamic> data = {
      "userId": userId,
      "controllerId": controllerId,
      "nodeControllerId": nodeControllerId,
      "fromDate": reqDateStr,
      "toDate": reqDateStr,
    };
    log("getUserVoltageLog request: $data silent=$silent");

    if (!silent) {
      isVoltageLoading = true;
      voltageData = []; // never show the previous day's rows
      voltageMessage = '';
      notifyListeners(); // screen shows the loader immediately
    }

    try {
      final res = await repository.getUserVoltageLog(data, nodeControllerId != 0);
      if (ticket != _voltageTicket) return;

      final response = jsonDecode(res.body);
      List<Map<String, dynamic>> newVoltage = [];
      String newMessage = '';

      if (res.statusCode == 200) {
        final raw = response['data'];
        final bool isToday = _isSameDay(requestedDate, DateTime.now());
        final int nowHour = DateTime.now().hour;

        List<dynamic>? hourlyItems;

        if (raw is Map && raw['voltageDetails'] is List) {
          hourlyItems = raw['voltageDetails'] as List;
        } else if (raw is List && raw.isNotEmpty) {
          final first = raw[0];
          if (first is Map &&
              (first.containsKey('hour') ||
                  first.containsKey('voltageR') ||
                  first.containsKey('voltage1'))) {
            hourlyItems = raw;
          } else {
            Map<String, dynamic>? targetEntry;
            bool anyEntryHadDate = false;

            for (final entry in raw) {
              if (entry is! Map) continue;
              final rawDate =
                  entry['date'] ?? entry['logDate'] ?? entry['fromDate'] ?? entry['createdDate'];
              if (rawDate == null) continue;
              anyEntryHadDate = true;

              final String dateStr = rawDate.toString().trim();
              final parsed = DateTime.tryParse(dateStr);
              if (dateStr.startsWith(reqDateStr) ||
                  (parsed != null && _isSameDay(parsed, requestedDate))) {
                targetEntry = Map<String, dynamic>.from(entry);
                break;
              }
            }

            // Only fall back to "first entry" when the server gave NO date info at all.
            // If dates exist but none match, that day simply has no data.
            if (targetEntry == null && !anyEntryHadDate) {
              for (final entry in raw) {
                if (entry is Map && entry['voltageDetails'] is List) {
                  targetEntry = Map<String, dynamic>.from(entry);
                  break;
                }
              }
            }

            if (targetEntry != null && targetEntry['voltageDetails'] is List) {
              hourlyItems = targetEntry['voltageDetails'] as List;
            }
          }
        }

        if (hourlyItems != null && hourlyItems.isNotEmpty) {
          for (final item in hourlyItems) {
            if (item is! Map) continue;
            final row = Map<String, dynamic>.from(item);
            final int? hour = _parseHour(row['hour']);
            if (hour == null || hour < 0 || hour > 23) continue;
            if (isToday && hour > nowHour) continue; // never show hours that have not happened
            row['hour'] = hour; // normalise: always an int
            newVoltage.add(row);
          }

          // One row per hour, in hour order. If the server sends an hour twice, the later one wins.
          final Map<int, Map<String, dynamic>> byHour = {};
          for (final r in newVoltage) {
            byHour[r['hour'] as int] = r;
          }
          newVoltage = (byHour.keys.toList()..sort()).map((h) => byHour[h]!).toList();

          if (newVoltage.isEmpty) {
            newMessage = 'No data available for the selected date.';
          } else {
            lastVoltageSync = DateTime.now();
          }
        } else {
          newMessage = 'No data available for the selected date.';
        }
      } else {
        newMessage = 'Failed to load data: ${response['message']}';
      }

      log("getUserVoltageLog applied for $reqDateStr: ${newVoltage.length} rows, msg='$newMessage'");
      voltageData = newVoltage;
      voltageMessage = newMessage;
    } catch (e, stackTrace) {
      if (ticket != _voltageTicket) return;
      log("getUserVoltageLog error: $e\n$stackTrace");
      if (!silent) {
        voltageData = [];
        voltageMessage = 'Error occurred: $e';
      }
    } finally {
      if (ticket == _voltageTicket) {
        if (!silent) isVoltageLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}