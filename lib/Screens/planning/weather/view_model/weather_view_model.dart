import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../repository/repository.dart';
import '../model/weather_model.dart';
import '../weather_report_model.dart';
import '../weather_report_sensor_modelGsm.dart';

class WeatherViewModel extends ChangeNotifier {
  final Repository repository;
  final MqttPayloadProvider? mqttPayloadProvider;

  WeatherModelNew? weatherModel;
  List<IrrigationLineExpanded> irrigationTree = [];
  bool isLoadingWeather = false;
  int? selectedSerialNumber;

  Map<int, List<LiveSensorValue>> liveCache = {};
  Map<int, List<LiveSensorValue>> apiLiveCache = {};
  Map<int, List<LiveSensorValue>> mqttLiveCache = {};
  Map<String, ConfigObjectNew> configIndex = {};
  Map<int, String> hourlyTempReport = {};

  bool _disposed = false;

  WeatherViewModel(this.repository, [this.mqttPayloadProvider]) {
    mqttPayloadProvider?.addListener(_onMqttPayloadChanged);
  }

  @override
  void dispose() {
    _disposed = true;
    mqttPayloadProvider?.removeListener(_onMqttPayloadChanged);
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Returns the 5101 string only when present in the expected MQTT envelope.
  /// Supported: {cM:{5101:'...'}}, {weatherLive:{cM:{5101:'...'}}},
  /// {5101:'...'}, and the same maps nested under data/message/payload.
  /// A raw string is accepted only if it resembles a 5101 serial payload.
  String _extract5101(dynamic input, [int depth = 0]) {
    if (input == null || depth > 6) return '';
    if (input is String) {
      final raw = input.trim();
      if (raw.isEmpty) return '';
      if (raw.startsWith('{') || raw.startsWith('[')) {
        try {
          return _extract5101(jsonDecode(raw), depth + 1);
        } catch (_) {
          return '';
        }
      }
      return parse5101Payload(raw).isNotEmpty ? raw : '';
    }
    if (input is Map) {
      if (input.containsKey('5101')) {
        return _extract5101(input['5101'], depth + 1);
      }
      for (final key in const ['cM', 'weatherLive', 'data', 'message', 'payload']) {
        if (input.containsKey(key)) {
          final found = _extract5101(input[key], depth + 1);
          if (found.isNotEmpty) return found;
        }
      }
    }
    if (input is List) {
      for (final item in input) {
        final found = _extract5101(item, depth + 1);
        if (found.isNotEmpty) return found;
      }
    }
    return '';
  }

  void _onMqttPayloadChanged() {
    if (_disposed || weatherModel == null || mqttPayloadProvider == null) return;
    final mqttModel = mqttPayloadProvider!.weatherModelinstance;
    final raw = _extract5101(mqttModel.data);
    mqttLiveCache = raw.isEmpty ? {} : parse5101Payload(raw);
    _mergeLiveCaches();
    if (kDebugMode) {
      debugPrint(mqttLiveCache.isEmpty
          ? 'Weather: MQTT 5101 empty, using API fallback'
          : 'Weather: MQTT 5101 active, API fallback per sensor');
    }
    _notify();
  }

  /// Merge at SENSOR level, not station level. A partial MQTT packet cannot
  /// erase other valid sensors from the API snapshot.
  void _mergeLiveCaches() {
    final merged = <int, Map<int, LiveSensorValue>>{};
    void insert(Map<int, List<LiveSensorValue>> source) {
      for (final entry in source.entries) {
        final bySensor = merged.putIfAbsent(entry.key, () => {});
        for (final sensor in entry.value) {
          bySensor[WeatherModelNew.sensorKey(sensor.sNo)] = sensor;
        }
      }
    }
    insert(apiLiveCache);
    insert(mqttLiveCache);
    liveCache = {
      for (final entry in merged.entries) entry.key: entry.value.values.toList(),
    };
  }

  Future<void> fetchWeatherData(int userId, int controllerId) async {
    isLoadingWeather = true;
    _notify();
    try {
      final response = await repository.getweather({
        'userId': userId,
        'controllerId': controllerId,
      });
      if (response != null && response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['code'] == 200 && decoded['data'] is Map) {
          weatherModel = WeatherModelNew.fromJson(
            Map<String, dynamic>.from(decoded['data'] as Map),
          );
          apiLiveCache = weatherModel!.parseLive5101();
          _buildConfigIndex();
          irrigationTree = weatherModel!.buildIrrigationLineTree();
          if (weatherModel!.deviceList.isNotEmpty) {
            final stillExists = weatherModel!.deviceList.any(
                  (d) => d.serialNumber == selectedSerialNumber,
            );
            if (!stillExists) {
              selectedSerialNumber = weatherModel!.deviceList.first.serialNumber;
            }
          } else {
            selectedSerialNumber = null;
          }
          // Re-read the current MQTT snapshot after loading API data.
          final raw = mqttPayloadProvider == null
              ? ''
              : _extract5101(mqttPayloadProvider!.weatherModelinstance.data);
          mqttLiveCache = raw.isEmpty ? {} : parse5101Payload(raw);
          _mergeLiveCaches();
          _notify();
          if (selectedSerialNumber != null) {
            await fetchHourlyTempReport(userId, controllerId);
          }
        }
      }
    } catch (e, st) {
      debugPrint('Weather error: $e\n$st');
    } finally {
      isLoadingWeather = false;
      _notify();
    }
  }

  Future<void> fetchWeatherDataGsm(
      int userId, int controllerId, Map<String, dynamic> data) async {
    isLoadingWeather = true;
    _notify();
    try {
      final source = data['data'] is Map ? data['data'] : data;
      if (source is Map) {
        weatherModel = WeatherModelNew.fromJson(Map<String, dynamic>.from(source));
        apiLiveCache = weatherModel!.parseLive5101();
        mqttLiveCache = {};
        _mergeLiveCaches();
        _buildConfigIndex();
        irrigationTree = weatherModel!.buildIrrigationLineTree();
        selectedSerialNumber = weatherModel!.deviceList.isNotEmpty
            ? weatherModel!.deviceList.first.serialNumber : null;
        if (selectedSerialNumber != null) {
          await fetchHourlyTempReport(userId, controllerId);
        }
      }
    } catch (e, st) {
      debugPrint('Weather GSM data error: $e\n$st');
    } finally {
      isLoadingWeather = false;
      _notify();
    }
  }

  Future<void> fetchHourlyTempReport(int userId, int controllerId) async {
    if (selectedSerialNumber == null) return;
    final tempConfig = configIndex['${controllerId}_Temperature Sensor'];
    if (tempConfig == null) return;
    final sNo = tempConfig.sNo.toString();
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final response = await repository.getweatherReport({
        'userId': userId.toString(),
        'controllerId': controllerId.toString(),
        'fromDate': date,
        'toDate': date,
      });
      if (response.statusCode != 200) return;
      final model = weatherReportModelFromJson(response.body);
      if (model.data.isEmpty) return;
      final datum = model.data.first;
      final hours = <String, String>{
        '00:00': datum.the0000, '01:00': datum.the0100,
        '02:00': datum.the0200, '03:00': datum.the0300,
        '04:00': datum.the0400, '05:00': datum.the0500,
        '06:00': datum.the0600, '07:00': datum.the0700,
        '08:00': datum.the0800, '09:00': datum.the0900,
        '10:00': datum.the1000, '11:00': datum.the1100,
        '12:00': datum.the1200, '13:00': datum.the1300,
        '14:00': datum.the1400, '15:00': datum.the1500,
        '16:00': datum.the1600, '17:00': datum.the1700,
        '18:00': datum.the1800, '19:00': datum.the1900,
        '20:00': datum.the2000, '21:00': datum.the2100,
        '22:00': datum.the2200, '23:00': datum.the2300,
      };
      final updated = <int, String>{};
      hours.forEach((hourStr, raw) {
        final data = parseSensorHourData(
          hour: hourStr,
          raw: raw,
          deviceSrNo: selectedSerialNumber.toString(),
          targetSensor: sNo,
        );
        if (data != null && data.value != 'NA') {
          updated[int.parse(hourStr.split(':').first)] = data.value;
        }
      });
      hourlyTempReport = updated;
      _notify();
    } catch (e) {
      debugPrint('Error fetching hourly report: $e');
    }
  }

  void _buildConfigIndex() {
    if (weatherModel == null) return;
    configIndex = {
      for (final c in weatherModel!.configObject)
        if (c.controllerId != null) '${c.controllerId}_${c.objectName}': c,
    };
  }

  bool get hasAnyWeatherStation => weatherModel?.deviceList.any(
        (d) => d.deviceName.toLowerCase().contains('weather'),
  ) ?? false;

  WeatherDeviceList? get selectedDevice {
    if (weatherModel == null || weatherModel!.deviceList.isEmpty ||
        selectedSerialNumber == null) return null;
    for (final device in weatherModel!.deviceList) {
      if (device.serialNumber == selectedSerialNumber) return device;
    }
    return weatherModel!.deviceList.first;
  }

  void selectDevice(int serial) {
    selectedSerialNumber = serial;
    _notify();
  }

  LiveSensorValue? getSensorLiveByName({
    required String objectName,
    required int controllerId,
  }) {
    if (selectedSerialNumber == null) return null;
    return getSensorLiveBySerial(
      serial: selectedSerialNumber!,
      objectName: objectName,
      controllerId: controllerId,
    );
  }

  String getSensorValueText({
    required String objectName,
    required int controllerId,
  }) {
    final sensor = getSensorLiveByName(
      objectName: objectName,
      controllerId: controllerId,
    );
    if (sensor == null || sensor.status == -1) return 'No Data';
    return sensor.value.toStringAsFixed(1);
  }

  LiveSensorValue? getSensorLiveBySerial({
    required int serial,
    required String objectName,
    required int controllerId,
    double? objectSno,
  }) {
    final config = configIndex['${controllerId}_$objectName'];
    if (config == null && objectSno == null) return null;
    final list = liveCache[serial];
    if (list == null) return null;
    final wantedKey = WeatherModelNew.sensorKey(objectSno ?? config!.sNo);
    for (final sensor in list) {
      if (WeatherModelNew.sensorKey(sensor.sNo) == wantedKey) return sensor;
    }
    return null;
  }

  PeriodSensorStats getSensorLast7Days(double sensorSNo) =>
      weatherModel?.getLast7DaysStats(sensorSNo) ??
          const PeriodSensorStats(min: 0, max: 0, average: 0);

  PeriodSensorStats getSensorLast30Days(double sensorSNo) =>
      weatherModel?.getLast30DaysStats(sensorSNo) ??
          const PeriodSensorStats(min: 0, max: 0, average: 0);
}
