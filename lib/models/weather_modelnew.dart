import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

class WeatherStation {
  final int deviceId; // Device ID (S_No for the weather station)
  final List<Sensor> sensors;

  WeatherStation({
    required this.deviceId,
    required this.sensors,
  });

  factory WeatherStation.fromString(String data) {
    AppLog.log('data: $data');
    final parts = data.split(',');
    AppLog.log('parts: $parts');
    final deviceId = int.parse(parts[0]); // First index is device ID
    final sensors = <Sensor>[];

    // Start at index 1, step by 3, ensure we have full triplets
    for (int i = 1; i < parts.length - 2; i += 3) {
      try {
        final sensorSno = double.parse(parts[i]);
        final value = double.parse(parts[i + 1]);
        final errorStatus = int.parse(parts[i + 2]);

        sensors.add(Sensor(
          sno: sensorSno,
          value: value,
          errorStatus: errorStatus,
        ));
      } catch (e) {
        AppLog.log('Error parsing sensor at index $i: $e');
        break;
      }
    }

    return WeatherStation(deviceId: deviceId, sensors: sensors);
  }
  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'sensors': sensors.map((s) => s.toJson()).toList(),
  };
}

class Sensor {
  final double sno; // Sensor S_No (using double as per your data)
  final double value; // Sensor Value
  final int errorStatus; // Sensor Error Status

  Sensor({
    required this.sno,
    required this.value,
    required this.errorStatus,
  });
  Map<String, dynamic> toJson() => {
    'sno': sno,
    'value': value,
    'errorStatus': errorStatus,
  };
}

class WeatherData {
  final String cC;
  final String cT;
  final String cD;
  final List<WeatherStation> stations;

  WeatherData({
    required this.cC,
    required this.cT,
    required this.cD,
    required this.stations,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final weatherLive = json['data']['weatherLive'];
    final cMString = weatherLive['cM']['5101'] as String;

    final stationStrings = cMString.contains(';') ? cMString.split(';') : [cMString];

    final stations = stationStrings
        .where((data) => data.trim().isNotEmpty)
        .map((data) => WeatherStation.fromString(data))
        .toList();

    return WeatherData(
      cC: weatherLive['cC'],
      cT: weatherLive['cT'],
      cD: weatherLive['cD'],
      stations: stations,
    );
  }

  Map<String, dynamic> toJson() => {
    'cC': cC,
    'cT': cT,
    'cD': cD,
    'stations': stations.map((s) => s.toJson()).toList(),
  };
}

class IrrigationLine {
  final int objectId;
  final String name;
  final List<int> weatherStation;

  IrrigationLine({
    required this.objectId,
    required this.name,
    required this.weatherStation,
  });

  factory IrrigationLine.fromJson(Map<String, dynamic> json) {
    return IrrigationLine(
      objectId: json['objectId'],
      name: json['name'],
      weatherStation: List<int>.from(json['weatherStation']),
    );
  }
  Map<String, dynamic> toJson() => {
    'objectId': objectId,
    'name': name,
    'weatherStation': weatherStation,
  };
}

class DeviceW {
  final int controllerId;
  final String deviceId;
  final String deviceName;
  final int serialNumber;

  DeviceW({
    required this.controllerId,
    required this.deviceId,
    required this.deviceName,
    required this.serialNumber,
  });

  factory DeviceW.fromJson(Map<String, dynamic> json) {
    return DeviceW(
      controllerId: json['controllerId'],
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      serialNumber: json['serialNumber'],
    );
  }
  Map<String, dynamic> toJson() => {
    'controllerId': controllerId,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'serialNumber': serialNumber,
  };
}

class ConfigObjectWeather {
  int objectId;
  double sNo;
  String name;
  String objectName;
  int? controllerId;
  double location;

  ConfigObjectWeather({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.controllerId,
    required this.location,
  });

  factory ConfigObjectWeather.fromJson(Map<String, dynamic> json) {
    return ConfigObjectWeather(
      objectId: json['objectId'],
      sNo: (json['sNo'] as num).toDouble(),
      name: json['name'],
      objectName: json['objectName'],
      controllerId: json['controllerId'],
      location: (json['location'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'objectId': objectId,
    'sNo': sNo,
    'name': name,
    'objectName': objectName,
    'controllerId': controllerId,
    'location': location,
  };
}

String? getConfigObjectNameBySNo(List<ConfigObjectWeather> objects, double sNo) {
  try {
    return objects.firstWhere((obj) => obj.sNo == sNo).name;
  } catch (e) {
    return null;
  }
}