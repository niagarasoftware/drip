import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../widgets/reusable_sensor_card.dart';
import 'package:provider/provider.dart';

import '../../../../StateManagement/mqtt_payload_provider.dart';
import '../../../../services/mqtt_service.dart';
import '../../../../utils/environment.dart';
import '../weather_report_monthly.dart';

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
      'sentSms': '#live'}
    );

    manager.topicToPublishAndItsMessage(
      payload,
      '${Environment.mqttPublishTopic}/${widget.deviceID}',
    );

  }

  @override
  Widget build(BuildContext context) {
    print('j,controllerId:${widget.controllerId},deviceID:${widget.deviceID},customerId:${widget.customerId}');
    final mqttPayloadProvider = Provider.of<MqttPayloadProvider>(context, listen: true);
    print("mqttPayloadProvider.weatherGSMModelinstance:${mqttPayloadProvider.weatherGSMModelinstance}");
    try {
      // Accept either the full API response or the data object itself.
      final responseData = widget.jsondata['data'] ?? widget.jsondata;
      final Map<String, dynamic> json = responseData is Map
          ? Map<String, dynamic>.from(responseData)
          : widget.jsondata;

      // Extract master list if present
      List masterList = [];
      if (json['master'] is List) {
        masterList = json['master'];
      } else if (json.containsKey('data') && json['data'] is Map && (json['data'] as Map)['master'] is List) {
        masterList = (json['data'] as Map)['master'];
      } else if (widget.jsondata['master'] is List) {
        masterList = widget.jsondata['master'];
      }

      Map<String, dynamic> selectedMaster = {};
      if (masterList.isNotEmpty) {
        selectedMaster = Map<String, dynamic>.from(
          masterList.firstWhere(
                (m) => m is Map &&
                (m['controllerId']?.toString() == widget.controllerId.toString() ||
                    m['deviceName']?.toString() == widget.deviceID.toString() ||
                    m['deviceId']?.toString() == widget.deviceID.toString()),
            orElse: () => masterList.first,
          ),
        );
      } else {
        selectedMaster = json;
      }

      debugPrint("WeatherGsm selectedControllerId: ${widget.controllerId}");
      debugPrint("WeatherGsm selectedMaster found: ${selectedMaster.isNotEmpty}");

      Map<String, dynamic> mqttData = {};
      if (mqttPayloadProvider.weatherGSMModelinstance.isNotEmpty) {
        try {
          final decoded = jsonDecode(mqttPayloadProvider.weatherGSMModelinstance);
          if (decoded is Map) {
            mqttData = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }

      final weatherLive = mqttData.containsKey('weatherLive')
          ? _asMap(mqttData['weatherLive'])
          : mqttData.containsKey('cM') && _asMap(mqttData['cM']).containsKey('weatherLive')
          ? _asMap(_asMap(mqttData['cM'])['weatherLive'])
          : _asMap(selectedMaster['weatherLive'] ?? json['weatherLive']);

      final cmMap = mqttData.containsKey('cM') ? _asMap(mqttData['cM']) : mqttData;
      final livePayload = cmMap['7901']?.toString() ?? mqttData['7901']?.toString() ?? '';
      final liveMap = mapBySNo(parseLive7901(livePayload));

      dynamic rawConfigObj = selectedMaster['configObject'];
      if (rawConfigObj == null && selectedMaster['config'] is Map) {
        rawConfigObj = selectedMaster['config']['configObject'];
      }
      rawConfigObj ??= json['configObject'];

      final configList = (rawConfigObj as List? ?? [])
          .whereType<Map>()
          .map(
            (item) => ConfigObject.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      // Historical values are API data; never override them with MQTT.
      // Search the original response independently of the live controller logic.
      final historicalController = _findHistoricalController(
        widget.jsondata,
        widget.controllerId,
        widget.deviceID,
      );
      final last7DaysStr = historicalController['last7Days']?.toString() ??
          selectedMaster['last7Days']?.toString() ??
          json['last7Days']?.toString() ?? '';
      final last30DaysStr = historicalController['last30Days']?.toString() ??
          selectedMaster['last30Days']?.toString() ??
          json['last30Days']?.toString() ?? '';

      debugPrint('WeatherGsm last7Days raw: $last7DaysStr');
      debugPrint('WeatherGsm last30Days raw: $last30DaysStr');
      final last7DaysMap = parsePeriodString(last7DaysStr);
      final last30DaysMap = parsePeriodString(last30DaysStr);
      debugPrint('WeatherGsm last7Days parsed: ${last7DaysMap.length}');
      debugPrint('WeatherGsm last30Days parsed: ${last30DaysMap.length}');

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

      final time = mqttData['cT']?.toString() ??
          weatherLive['cT']?.toString() ??
          json['cT']?.toString() ?? '';
      final date = mqttData['cD']?.toString() ??
          weatherLive['cD']?.toString() ??
          json['cD']?.toString() ?? '';
      final dateTime = (date.isNotEmpty && time.isNotEmpty)
          ? '$date $time'
          : (date.isNotEmpty ? date : (time.isNotEmpty ? time : '--'));

      return _buildDashboard(sensors, dateTime);
    } catch (error, stackTrace) {
      debugPrint('WeatherGsm error: $error');
      debugPrint('$stackTrace');

      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No weather data available  \n$error',
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

  Widget _buildDashboard(List<SensorDisplayModel> sensors, String dateTime) {
    final ordered = _orderSensors(sensors);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1250 ? 4 : width >= 900 ? 3 : width >= 580 ? 2 : 1;
      const gap = 14.0;
      final cardWidth = (width - 32 - gap * (columns - 1)) / columns;
      return RefreshIndicator(
        onRefresh: () async => _requestLiveData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Weather', style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w700,
                )),
                Text('Live: $dateTime', style: const TextStyle(color: Colors.black54)),
                IconButton(
                  tooltip: 'Request live data',
                  onPressed: _requestLiveData,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (ordered.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No sensors available')))
            else
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final sensor in ordered)
                    SizedBox(
                      width: cardWidth > 0 ? cardWidth : width,
                      child: ReusableSensorCard(
                        title: sensor.name,
                        icon: _sensorIcon(sensor.name),
                        accent: _sensorAccent(sensor.name),
                        unit: _unit(sensor.name),
                        value: sensor.value,
                        statusCode: sensor.status,
                        todayMin: sensor.min,
                        todayMax: sensor.max,
                        todayAverage: sensor.average,
                        weekAverage: sensor.last7DaysAverage,
                        monthAverage: sensor.last30DaysAverage,
                        isWindDirection: sensor.name.toLowerCase().contains('wind direction'),
                        onWeekTap: () => _openReport(sensor),
                        onMonthTap: () => _openReport(sensor),
                        onCurrentTap: () => _openReport(sensor),
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
    });
  }

  List<SensorDisplayModel> _orderSensors(List<SensorDisplayModel> sensors) {
    final regular = sensors.where((sensor) {
      final name = sensor.name.toLowerCase();
      return !name.contains('co2') && !name.contains('rain') && !name.contains('wind direction');
    });
    final special = sensors.where((sensor) {
      final name = sensor.name.toLowerCase();
      return name.contains('co2') || name.contains('rain') || name.contains('wind direction');
    });
    return [...regular, ...special];
  }

  void _openReport(SensorDisplayModel sensor) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SensorHourlyReportPage(
      deviceSrNo: '1', // Existing GSM sensor serial; replace if actual serial differs.
      sensorSrNo: sensor.sNo.toString(),
      sensorName: sensor.name,
      userId: widget.customerId.toString(),
      controllerId: widget.controllerId.toString(),
      unit: _unit(sensor.name),
    )));
  }

  String _unit(String type) {
    final name = type.toLowerCase();
    if (name.contains('moisture')) return 'CB';
    if (name.contains('temperature')) return '°C';
    if (name.contains('humidity') || name.contains('leaf')) return '%';
    if (name.contains('co2')) return 'ppm';
    if (name.contains('direction')) return '°';
    if (name.contains('wind')) return 'km/h';
    if (name.contains('rain')) return 'mm';
    if (name.contains('lux')) return 'Lu';
    if (name.contains('ldr')) return 'Ω';
    return '';
  }

  IconData _sensorIcon(String type) {
    final n = type.toLowerCase();
    if (n.contains('direction')) return Icons.explore_outlined;
    if (n.contains('moisture')) return Icons.grass;
    if (n.contains('temperature')) return Icons.thermostat;
    if (n.contains('humidity') || n.contains('leaf')) return Icons.water_drop_outlined;
    if (n.contains('wind')) return Icons.air;
    if (n.contains('rain')) return Icons.water_drop;
    if (n.contains('lux') || n.contains('ldr')) return Icons.wb_sunny_outlined;
    if (n.contains('co2')) return Icons.cloud_outlined;
    return Icons.sensors;
  }

  Color _sensorAccent(String type) {
    final n = type.toLowerCase();
    if (n.contains('moisture')) return const Color(0xFF159B74);
    if (n.contains('temperature')) return const Color(0xFFEA7845);
    if (n.contains('wind')) return const Color(0xFF3684D8);
    if (n.contains('rain') || n.contains('humidity')) return const Color(0xFF298BC8);
    if (n.contains('lux')) return const Color(0xFFE5A21D);
    return const Color(0xFF6C7A89);
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


// Find API historical readings without altering existing live/MQTT selection.
Map<String, dynamic> _findHistoricalController(
    dynamic source,
    int controllerId,
    String deviceId,
    ) {
  final candidates = <Map<String, dynamic>>[];

  void visit(dynamic value) {
    if (value is List) {
      for (final item in value) {
        visit(item);
      }
      return;
    }
    if (value is! Map) return;
    final map = Map<String, dynamic>.from(value);
    if (map.containsKey('last7Days') || map.containsKey('last30Days')) {
      candidates.add(map);
    }
    if (map.containsKey('data')) visit(map['data']);
    if (map.containsKey('master')) visit(map['master']);
  }

  visit(source);
  for (final item in candidates) {
    if (item['controllerId']?.toString() == controllerId.toString()) {
      return item;
    }
  }
  for (final item in candidates) {
    if (item['deviceId']?.toString().trim().toLowerCase() ==
        deviceId.trim().toLowerCase()) {
      return item;
    }
  }
  if (candidates.length == 1) return candidates.first;
  debugPrint('WeatherGsm: no matching historical controller '
      '(candidates: ${candidates.length})');
  return <String, dynamic>{};
}

int _sensorKey(double sNo) => (sNo * 1000).round();

Map<int, PeriodSensorValue> parsePeriodString(String raw) {
  final result = <int, PeriodSensorValue>{};
  if (raw.isEmpty) return result;

  for (final record in raw.split('_')) {
    if (record.trim().isEmpty) continue;
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
