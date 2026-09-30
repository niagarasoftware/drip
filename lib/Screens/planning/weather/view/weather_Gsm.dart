import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/planning/weather/widgets/sensor_tile_new.dart';

import '../../../../services/mqtt_service.dart';
import '../../../../utils/environment.dart';
import '../weather_report_monthly.dart';
import '../widgets/info_box.dart';
import '../widgets/sun_time_card.dart';
import '../widgets/time_of_day_icon_new.dart';

class WeatherGsm extends StatefulWidget {
  const WeatherGsm({
    super.key,
    required this.customerId,
    required this.controllerId,
    required this.deviceID,
    required this.jsondata,
  });

  final int customerId;
  final int controllerId;
  final String deviceID;
  final Map<String, dynamic> jsondata;

  @override
  State<WeatherGsm> createState() => _WeatherGsmState();
}

class _WeatherGsmState extends State<WeatherGsm> {
  final MqttService manager = MqttService();
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
          (_) {
        if (mounted) _requestLiveData();
      },
    );
  }

  void _requestLiveData() {
    final payload = jsonEncode({
      '5000': {'5001': ''},
    });

    manager.topicToPublishAndItsMessage(
      payload,
      '${Environment.mqttPublishTopic}/${widget.deviceID}',
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Accept either the full API response or the data object itself.
      final responseData = widget.jsondata['data'];
      final Map<String, dynamic> json = responseData is Map
          ? Map<String, dynamic>.from(responseData)
          : widget.jsondata;

      final weatherLive = _asMap(json['weatherLive']);
      final cm = _asMap(weatherLive['cM']);

      final liveMap = mapBySNo(
        parseLive7901(cm['7901']?.toString() ?? ''),
      );

      final configList = (json['configObject'] as List? ?? [])
          .whereType<Map>()
          .map(
            (item) => ConfigObject.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      final last7DaysMap = parsePeriodString(
        json['last7Days']?.toString() ?? '',
      );
      final last30DaysMap = parsePeriodString(
        json['last30Days']?.toString() ?? '',
      );

      final sensors = buildSensorList(
        configs: configList,
        liveMap: liveMap,
        last7DaysMap: last7DaysMap,
        last30DaysMap: last30DaysMap,
      );

      String sensorValue(String sensorName) {
        for (final sensor in sensors) {
          if (sensor.name.toLowerCase().contains(sensorName.toLowerCase())) {
            return sensor.value.toStringAsFixed(1);
          }
        }
        return '--';
      }

      final temperature = sensorValue('Temperature Sensor');
      final wind = sensorValue('Wind Speed Sensor');
      final humidity = sensorValue('Humidity Sensor');

      final time = weatherLive['cT']?.toString() ?? '';
      final date = weatherLive['cD']?.toString() ?? '';
      final dateTime = '$time-$date';

      return kIsWeb
          ? _buildWideLayout(
        sensors,
        dateTime,
        temperature,
        wind,
        humidity,
        time,
      )
          : _buildNarrowLayout(
        sensors,
        dateTime,
        temperature,
        wind,
        humidity,
        time,
      );
    } catch (error, stackTrace) {
      debugPrint('WeatherGsm error: $error');
      debugPrint('$stackTrace');

      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Something went wrong\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildWideLayout(
      List<SensorDisplayModel> sensors,
      String dateTime,
      String temperature,
      String wind,
      String humidity,
      String time,
      ) {
    final orderedSensors = _orderSensors(sensors);

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 320,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _requestLiveData,
                    ),
                    const Text('Get Live Data'),
                  ],
                ),
                _weatherSummaryCard(
                  dateTime,
                  temperature,
                  wind,
                  humidity,
                  time,
                ),
                const SizedBox(height: 16),
                _sunCard(),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _requestLiveData();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: orderedSensors
                        .map(
                          (sensor) => _sensorCard(
                        sensor,
                        isNarrow: false,
                      ),
                    )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
      List<SensorDisplayModel> sensors,
      String dateTime,
      String temperature,
      String wind,
      String humidity,
      String time,
      ) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _requestLiveData,
            ),
            const Text('Get Live Data'),
          ],
        ),
        _weatherSummaryCard(
          dateTime,
          temperature,
          wind,
          humidity,
          time,
        ),
        const SizedBox(height: 16),
        _sunCard(),
        const SizedBox(height: 16),

        // One separate card for every sensor.
        for (final sensor in sensors)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _sensorCard(
              sensor,
              isNarrow: true,
            ),
          ),
      ],
    );
  }

  Widget _sensorCard(
      SensorDisplayModel sensor, {
        required bool isNarrow,
      }) {
    return SizedBox(
      width: isNarrow ? double.infinity : 310,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openHourlyReport(sensor),
            child: SensorTileNew(
              icon: Icons.sensors,
              title: sensor.name,
              statusCode: sensor.status,
              value: sensor.value,
              unit: _unit(sensor.name),

              // Current day values
              minValue: sensor.min,
              maxValue: sensor.max,
              otherValue: sensor.average.toString(),

              // Last 7 days values
              last7DaysMin: sensor.last7DaysMin,
              last7DaysMax: sensor.last7DaysMax,
              last7DaysAverage: sensor.last7DaysAverage,

              // Last 30 days values
              last30DaysMin: sensor.last30DaysMin,
              last30DaysMax: sensor.last30DaysMax,
              last30DaysAverage: sensor.last30DaysAverage,
            ),
          ),
        ),
      ),
    );
  }

  List<SensorDisplayModel> _orderSensors(
      List<SensorDisplayModel> sensors,
      ) {
    final regular = sensors.where((sensor) {
      final name = sensor.name.toLowerCase();
      return !name.contains('co2') &&
          !name.contains('rain fall') &&
          !name.contains('wind direction');
    });

    final special = sensors.where((sensor) {
      final name = sensor.name.toLowerCase();
      return name.contains('co2') ||
          name.contains('rain fall') ||
          name.contains('wind direction');
    });

    return [...regular, ...special];
  }

  void _openHourlyReport(SensorDisplayModel sensor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SensorHourlyReportPage(
          deviceSrNo: '1',
          sensorSrNo: sensor.sNo.toString(),
          sensorName: sensor.name,
          userId: widget.customerId.toString(),
          controllerId: widget.controllerId.toString(),
          unit: _unit(sensor.name),
        ),
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

  Widget _weatherSummaryCard(
      String dateTime,
      String temperature,
      String wind,
      String humidity,
      String time,
      ) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.location_solid),
              SizedBox(width: 6),
              Text('Coimbatore'),
            ],
          ),
          const SizedBox(height: 12),
          Text(dateTime),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$temperature °C',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Feel Like $temperature °C'),
                ],
              ),
              const SizedBox(width: 30),
              TimeOfDayIconNew(time: time),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InfoBox(
                  CupertinoIcons.wind,
                  'Wind',
                  wind,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InfoBox(
                  CupertinoIcons.drop_fill,
                  'Humidity',
                  humidity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sunCard() {
    return const Row(
      children: [
        Expanded(
          child: SunTimeCard(
            'Sunrise',
            '6:10 AM',
            'assets/Images/sunrise.png',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: SunTimeCard(
            'Sunset',
            '6:45 PM',
            'assets/Images/sunset.png',
          ),
        ),
      ],
    );
  }
}

class LiveSensorValue {
  final double sNo;
  final double value;
  final int status;
  final double min;
  final double max;
  final double average;

  const LiveSensorValue({
    required this.sNo,
    required this.value,
    required this.status,
    required this.min,
    required this.max,
    required this.average,
  });
}

class PeriodSensorValue {
  final double min;
  final double max;
  final double average;

  const PeriodSensorValue({
    required this.min,
    required this.max,
    required this.average,
  });

  static const empty = PeriodSensorValue(
    min: 0,
    max: 0,
    average: 0,
  );
}

class ConfigObject {
  final double sNo;
  final String name;
  final int objectId;

  const ConfigObject({
    required this.sNo,
    required this.name,
    required this.objectId,
  });

  factory ConfigObject.fromJson(Map<String, dynamic> json) {
    return ConfigObject(
      sNo: _toDouble(json['sNo']),
      name: json['name']?.toString() ?? '',
      objectId: _toInt(json['objectId']),
    );
  }
}

class SensorDisplayModel {
  final String name;
  final double sNo;
  final double value;
  final int status;

  // Current day
  final double min;
  final double max;
  final double average;

  // Last 7 days
  final double last7DaysMin;
  final double last7DaysMax;
  final double last7DaysAverage;

  // Last 30 days
  final double last30DaysMin;
  final double last30DaysMax;
  final double last30DaysAverage;

  final int objectId;

  const SensorDisplayModel({
    required this.name,
    required this.sNo,
    required this.value,
    required this.status,
    required this.min,
    required this.max,
    required this.average,
    required this.last7DaysMin,
    required this.last7DaysMax,
    required this.last7DaysAverage,
    required this.last30DaysMin,
    required this.last30DaysMax,
    required this.last30DaysAverage,
    required this.objectId,
  });
}

int _sensorKey(double sNo) => (sNo * 1000).round();

Map<int, PeriodSensorValue> parsePeriodString(String raw) {
  final result = <int, PeriodSensorValue>{};

  for (final record in raw.split('_')) {
    final fields = record.split(',');
    if (fields.length < 4) continue;

    final sNo = double.tryParse(fields[0].trim());
    if (sNo == null) continue;

    result[_sensorKey(sNo)] = PeriodSensorValue(
      min: double.tryParse(fields[1].trim()) ?? 0,
      max: double.tryParse(fields[2].trim()) ?? 0,
      average: double.tryParse(fields[3].trim()) ?? 0,
    );
  }

  return result;
}

Map<int, List<LiveSensorValue>> parseLive7901(String raw) {
  final result = <int, List<LiveSensorValue>>{};

  if (raw.isEmpty) return result;

  for (final part in raw.split(';')) {
    final colonIndex = part.indexOf(':');
    if (colonIndex == -1) continue;

    final header = part.substring(0, colonIndex);
    final payload = part.substring(colonIndex + 1);

    final serial = int.tryParse(header.split(',').first.trim());
    if (serial == null) continue;

    final sensors = <LiveSensorValue>[];

    for (final block in payload.split('_')) {
      final fields = block.split(',');
      if (fields.length < 5) continue;

      final sNo = double.tryParse(fields[0].trim());
      if (sNo == null) continue;

      sensors.add(
        LiveSensorValue(
          sNo: sNo,
          value: double.tryParse(fields[1].trim()) ?? 0,
          status: int.tryParse(fields[2].trim()) ?? 0,
          min: double.tryParse(fields[3].trim()) ?? 0,
          max: double.tryParse(fields[4].trim()) ?? 0,
          average: fields.length > 5
              ? double.tryParse(fields[5].trim()) ?? 0
              : 0,
        ),
      );
    }

    result[serial] = sensors;
  }

  return result;
}

Map<int, LiveSensorValue> mapBySNo(
    Map<int, List<LiveSensorValue>> liveData,
    ) {
  final result = <int, LiveSensorValue>{};

  for (final sensors in liveData.values) {
    for (final sensor in sensors) {
      result[_sensorKey(sensor.sNo)] = sensor;
    }
  }

  return result;
}

List<SensorDisplayModel> buildSensorList({
  required List<ConfigObject> configs,
  required Map<int, LiveSensorValue> liveMap,
  required Map<int, PeriodSensorValue> last7DaysMap,
  required Map<int, PeriodSensorValue> last30DaysMap,
}) {
  return configs.map((config) {
    final key = _sensorKey(config.sNo);
    final live = liveMap[key];
    final last7 = last7DaysMap[key] ?? PeriodSensorValue.empty;
    final last30 = last30DaysMap[key] ?? PeriodSensorValue.empty;

    return SensorDisplayModel(
      name: config.name,
      sNo: config.sNo,
      value: live?.value ?? 0,
      status: live?.status ?? 0,
      min: live?.min ?? 0,
      max: live?.max ?? 0,
      average: live?.average ?? 0,
      last7DaysMin: last7.min,
      last7DaysMax: last7.max,
      last7DaysAverage: last7.average,
      last30DaysMin: last30.min,
      last30DaysMax: last30.max,
      last30DaysAverage: last30.average,
      objectId: config.objectId,
    );
  }).toList();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}