class WeatherModelNew {
  final WeatherLive weatherLive;
  final List<WeatherDeviceList> deviceList;
  final List<IrrigationLine> irrigationLine;
  final List<ConfigObjectNew> configObject;
  final String last7Days;
  final String last30Days;

  WeatherModelNew({
    required this.weatherLive,
    required this.deviceList,
    required this.irrigationLine,
    required this.configObject,
    this.last7Days = '',
    this.last30Days = '',
  });

  factory WeatherModelNew.fromJson(Map<String, dynamic> json) {
    return WeatherModelNew(
      weatherLive: WeatherLive.fromJson(_jsonMap(json['weatherLive'])),
      deviceList: (json['deviceList'] as List? ?? [])
          .map((item) => WeatherDeviceList.fromJson(_jsonMap(item))).toList(),
      irrigationLine: (json['irrigationLine'] as List? ?? [])
          .map((item) => IrrigationLine.fromJson(_jsonMap(item))).toList(),
      configObject: (json['configObject'] as List? ?? [])
          .map((item) => ConfigObjectNew.fromJson(_jsonMap(item))).toList(),
      last7Days: json['last7Days']?.toString() ?? '',
      last30Days: json['last30Days']?.toString() ?? '',
    );
  }

  PeriodSensorStats getLast7DaysStats(double sensorSNo) =>
      _getPeriodStats(last7Days, sensorSNo);

  PeriodSensorStats getLast30DaysStats(double sensorSNo) =>
      _getPeriodStats(last30Days, sensorSNo);

  PeriodSensorStats _getPeriodStats(String raw, double sensorSNo) {
    final wantedKey = sensorKey(sensorSNo);
    for (final record in raw.split('_')) {
      final fields = record.split(',');
      if (fields.length < 4) continue;
      final recordSNo = double.tryParse(fields[0].trim());
      if (recordSNo == null || sensorKey(recordSNo) != wantedKey) continue;
      return PeriodSensorStats(
        min: double.tryParse(fields[1].trim()) ?? 0,
        max: double.tryParse(fields[2].trim()) ?? 0,
        average: double.tryParse(fields[3].trim()) ?? 0,
      );
    }
    return const PeriodSensorStats(min: 0, max: 0, average: 0);
  }

  static int sensorKey(double sNo) => (sNo * 1000).round();
}

class PeriodSensorStats {
  final double min;
  final double max;
  final double average;
  const PeriodSensorStats({
    required this.min,
    required this.max,
    required this.average,
  });
}

class WeatherLive {
  final String cC;
  final CM cM;
  final DateTime cD;
  final String cT;
  final String mC;

  WeatherLive({
    required this.cC,
    required this.cM,
    required this.cD,
    required this.cT,
    required this.mC,
  });

  factory WeatherLive.fromJson(Map<String, dynamic> json) {
    return WeatherLive(
      cC: json['cC']?.toString() ?? '',
      cM: CM.fromJson(_jsonMap(json['cM'])),
      cD: DateTime.tryParse(json['cD']?.toString() ?? '') ?? DateTime.now(),
      cT: json['cT']?.toString() ?? '00:00',
      mC: json['mC']?.toString() ?? '',
    );
  }
}

class CM {
  final Map<String, dynamic> raw;
  CM({required this.raw});
  factory CM.fromJson(Map<String, dynamic> json) =>
      CM(raw: Map<String, dynamic>.from(json));
  String get5101() => raw['5101']?.toString() ?? '';
}

class WeatherDeviceList {
  final int controllerId;
  final String deviceId;
  final String deviceName;
  final int serialNumber;

  WeatherDeviceList({
    required this.controllerId,
    required this.deviceId,
    required this.deviceName,
    required this.serialNumber,
  });

  factory WeatherDeviceList.fromJson(Map<String, dynamic> json) {
    return WeatherDeviceList(
      controllerId: _intValue(json['controllerId']),
      deviceId: json['deviceId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? '',
      serialNumber: _intValue(json['serialNumber']),
    );
  }
}

class IrrigationLine {
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  final List<int> weatherStation;

  IrrigationLine({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.weatherStation,
  });

  factory IrrigationLine.fromJson(Map<String, dynamic> json) {
    return IrrigationLine(
      objectId: _intValue(json['objectId']),
      sNo: _doubleValue(json['sNo']),
      name: json['name']?.toString() ?? '',
      objectName: json['objectName']?.toString() ?? '',
      weatherStation: (json['weatherStation'] as List? ?? [])
          .map(_intValue).toList(),
    );
  }
}

class ConfigObjectNew {
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  final int? controllerId;
  final double location;

  ConfigObjectNew({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.controllerId,
    required this.location,
  });

  factory ConfigObjectNew.fromJson(Map<String, dynamic> json) {
    return ConfigObjectNew(
      objectId: _intValue(json['objectId']),
      sNo: _doubleValue(json['sNo']),
      name: json['name']?.toString() ?? '',
      objectName: json['objectName']?.toString() ?? '',
      controllerId: json['controllerId'] == null
          ? null : _intValue(json['controllerId']),
      location: _doubleValue(json['location']),
    );
  }
}

class WeatherStationWithSensors {
  final WeatherDeviceList device;
  final List<ConfigObjectNew> sensors;
  WeatherStationWithSensors({required this.device, required this.sensors});
}

class IrrigationLineExpanded {
  final IrrigationLine line;
  final List<WeatherStationWithSensors> stations;
  IrrigationLineExpanded({required this.line, required this.stations});
}

class LiveSensorValue {
  final double sNo;
  final double value;
  final int status;
  final double min;
  final double max;
  final double avg;

  LiveSensorValue({
    required this.sNo,
    required this.value,
    required this.status,
    required this.min,
    required this.max,
    required this.avg,
  });
}

extension WeatherModelTreeBuilder on WeatherModelNew {
  List<IrrigationLineExpanded> buildIrrigationLineTree() {
    final result = <IrrigationLineExpanded>[];
    for (final line in irrigationLine) {
      final stations = <WeatherStationWithSensors>[];
      for (final controllerId in line.weatherStation) {
        final device = deviceList.firstWhere(
              (item) => item.controllerId == controllerId,
          orElse: () => WeatherDeviceList(
            controllerId: controllerId,
            deviceId: '',
            deviceName: 'Unknown Device',
            serialNumber: -1,
          ),
        );
        final sensors = configObject
            .where((item) => item.controllerId == controllerId).toList();
        stations.add(WeatherStationWithSensors(device: device, sensors: sensors));
      }
      result.add(IrrigationLineExpanded(line: line, stations: stations));
    }
    return result;
  }

  Map<int, List<LiveSensorValue>> parseLive5101() =>
      parse5101Payload(weatherLive.cM.get5101());
}

/// Both API and MQTT use the same 5101 payload grammar:
/// serial,header: sNo,value,status,min,max[,avg]_...;serial,...:...
Map<int, List<LiveSensorValue>> parse5101Payload(String raw) {
  final result = <int, List<LiveSensorValue>>{};
  if (raw.trim().isEmpty) return result;
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
      final value = double.tryParse(fields[1].trim());
      final status = int.tryParse(fields[2].trim());
      if (sNo == null || value == null || status == null) continue;
      sensors.add(LiveSensorValue(
        sNo: sNo,
        value: value,
        status: status,
        min: double.tryParse(fields[3].trim()) ?? 0,
        max: double.tryParse(fields[4].trim()) ?? 0,
        avg: fields.length > 5
            ? double.tryParse(fields[5].trim()) ?? 0 : 0,
      ));
    }
    if (sensors.isNotEmpty) result[serial] = sensors;
  }
  return result;
}

Map<String, dynamic> _jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleValue(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
