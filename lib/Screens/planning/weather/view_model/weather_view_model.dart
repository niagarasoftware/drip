import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../repository/repository.dart';
import '../model/weather_model.dart';
import '../weather_report_model.dart';
import '../weather_report_sensor_modelGsm.dart';

class WeatherViewModel extends ChangeNotifier {
  final Repository repository;

  WeatherModelNew? weatherModel;

  /// irrigation → stations → sensors tree
  List<IrrigationLineExpanded> irrigationTree = [];

  bool isLoadingWeather = false;
  int? selectedSerialNumber;

  /// parsed live cache (serial → sensor list)
  Map<int, List<LiveSensorValue>> liveCache = {};

  /// fast config lookup
  Map<String, ConfigObjectNew> configIndex = {};

  /// Hourly temperature report (hour -> value)
  Map<int, String> hourlyTempReport = {};

  WeatherViewModel(this.repository);

  Future<void> fetchWeatherData(int userId, int controllerId) async {
    if (kDebugMode) {
      print("Call fetchWeatherData call ");
    }
    isLoadingWeather = true;
    notifyListeners();

    try {
      final body = {
        "userId": userId,
        "controllerId": controllerId,
      };

      final response = await repository.getweather(body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print('data:$data');
        }

        if (data != null && data["code"] == 200 && data["data"] != null) {
          weatherModel = WeatherModelNew.fromJson(data["data"]);
          liveCache = weatherModel?.parseLive5101() ?? {};
          _buildConfigIndex();
          irrigationTree = weatherModel?.buildIrrigationLineTree() ?? [];

          final deviceList = weatherModel?.deviceList;
          if (deviceList != null && deviceList.isNotEmpty) {
            selectedSerialNumber = deviceList.first.serialNumber;
            // Fetch hourly report data
            await fetchHourlyTempReport(userId, controllerId);
          }
        }
      }
    } catch (e, st) {
      debugPrint("Weather error: $e\n$st");
    }

    isLoadingWeather = false;
    notifyListeners();
  }

  Future<void> fetchWeatherDataGsm(int userId, int controllerId, Map<String, dynamic> data) async {
    if (kDebugMode) {
      print("call fetchWeatherDataGsm");
    }
    isLoadingWeather = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('data:$data');
      }
      if (data["data"] != null) {
        weatherModel = WeatherModelNew.fromJson(data["data"]);
        liveCache = weatherModel?.parseLive5101() ?? {};
        _buildConfigIndex();
        irrigationTree = weatherModel?.buildIrrigationLineTree() ?? [];
        final deviceList = weatherModel?.deviceList;
        if (deviceList != null && deviceList.isNotEmpty) {
          selectedSerialNumber = deviceList.first.serialNumber;
          await fetchHourlyTempReport(userId, controllerId);
        }
      }
    } catch (e, st) {
      debugPrint("Weather error: $e\n$st");
    }
    isLoadingWeather = false;
    notifyListeners();
  }

  Future<void> fetchHourlyTempReport(int userId, int controllerId) async {
    if (selectedSerialNumber == null) return;

    final tempConfig = configIndex["${controllerId}_Temperature Sensor"];
    if (tempConfig == null) return;

    final String sNo = tempConfig.sNo.toString();
    final String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final response = await repository.getweatherReport({
        "userId": userId.toString(),
        "controllerId": controllerId.toString(),
        "fromDate": date,
        "toDate": date,
      });

      if (response.statusCode == 200) {
        final model = weatherReportModelFromJson(response.body);
        if (model.data.isEmpty) return;

        final datum = model.data.first;
        final Map<String, String> hours = {
          "00:00": datum.the0000,
          "01:00": datum.the0100,
          "02:00": datum.the0200,
          "03:00": datum.the0300,
          "04:00": datum.the0400,
          "05:00": datum.the0500,
          "06:00": datum.the0600,
          "07:00": datum.the0700,
          "08:00": datum.the0800,
          "09:00": datum.the0900,
          "10:00": datum.the1000,
          "11:00": datum.the1100,
          "12:00": datum.the1200,
          "13:00": datum.the1300,
          "14:00": datum.the1400,
          "15:00": datum.the1500,
          "16:00": datum.the1600,
          "17:00": datum.the1700,
          "18:00": datum.the1800,
          "19:00": datum.the1900,
          "20:00": datum.the2000,
          "21:00": datum.the2100,
          "22:00": datum.the2200,
          "23:00": datum.the2300,
        };

        hourlyTempReport.clear();
    hours.forEach((hourStr, raw) {
      final data = parseSensorHourData(
        hour: hourStr,
        raw: raw,
        deviceSrNo: selectedSerialNumber.toString(),
        targetSensor: sNo,
      );
      if (data != null && data.value != "NA") {
        int hourInt = int.parse(hourStr.split(':').first);
        hourlyTempReport[hourInt] = data.value;
      }
    });
      }
    } catch (e) {
      debugPrint("Error fetching hourly report: $e");
    }
  }

  void _buildConfigIndex() {
    if (weatherModel == null) return;

    configIndex = {
      for (final c in weatherModel!.configObject)
        if (c.controllerId != null)
          "${c.controllerId}_${c.objectName}": c
    };
  }

  bool get hasAnyWeatherStation {
    if (weatherModel == null) return false;

    return weatherModel!.deviceList.any(
      (d) => d.deviceName.toLowerCase().contains('weather'),
    );
  }

  WeatherDeviceList? get selectedDevice {
    if (weatherModel == null || selectedSerialNumber == null) return null;

    return weatherModel!.deviceList.firstWhere(
      (d) => d.serialNumber == selectedSerialNumber,
      orElse: () => weatherModel!.deviceList.first,
    );
  }

  void selectDevice(int serial) {
    selectedSerialNumber = serial;
    notifyListeners();
  }

  LiveSensorValue? getSensorLiveByName({
    required String objectName,
    required int controllerId,
  }) {
    if (selectedSerialNumber == null) return null;

    final config = configIndex["${controllerId}_$objectName"];
    if (config == null) return null;

    final list = liveCache[selectedSerialNumber!];
    if (list == null) return null;

    return list.firstWhere(
      (e) => e.sNo.toInt() == config.sNo.toInt(),
      orElse: () => LiveSensorValue(
        sNo: 0,
        value: 0,
        status: -1,
        min: 0,
        max: 0,
        avg: 0,
      ),
    );
  }

  /// helper → get formatted value string
  String getSensorValueText({
    required String objectName,
    required int controllerId,
  }) {
    final s = getSensorLiveByName(
      objectName: objectName,
      controllerId: controllerId,
    );

    if (s == null || s.status == -1) return "No Data";

    return s.value.toStringAsFixed(1);
  }

  LiveSensorValue? getSensorLiveBySerial({
    required int serial,
    required String objectName,
    required int controllerId,
    double? objectSno,
  }) {
    final config = configIndex["${controllerId}_$objectName"];
    if (config == null) return null;

    final list = liveCache[serial];
    if (list == null) return null;

    return list.firstWhere(
      (e) {
        if (objectSno != null) {
          return e.sNo == objectSno;
        } else {
          return e.sNo == config.sNo;
        }
      },
      orElse: () => LiveSensorValue(
        sNo: 0,
        value: 0,
        status: -1,
        min: 0,
        max: 0,
        avg: 0,
      ),
    );
  }
}
