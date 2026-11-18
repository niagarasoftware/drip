import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';

/// Parse main response from JSON
ValveResponseModel valveResponseModelFromJson(String str) =>
    ValveResponseModel.fromJson(json.decode(str));

 class ValveResponseModel {
  int? code;
  String? message;
  ValveData? data;

  ValveResponseModel({
    this.code,
    this.message,
    this.data,
  });

  factory ValveResponseModel.fromJson(Map<String, dynamic> json) =>
      ValveResponseModel(
        code: json["code"],
        message: json["message"],
        data:
        json["data"] != null ? ValveData.fromJson(json["data"]) : null,
      );
}

 class ValveData {
  List<Mapobject>? valveGeographyArea;
  Map<String, dynamic>? liveMessage;

  ValveData({
    this.valveGeographyArea,
    this.liveMessage,
  });

  factory ValveData.fromJson(Map<String, dynamic> json) => ValveData(
    valveGeographyArea: json["valveGeographyArea"] == null
        ? []
        : List<Mapobject>.from(
        json["valveGeographyArea"]
            .map((x) => Mapobject.fromJson(x))),
    liveMessage: json["liveMessage"],
  );

  Map<String, dynamic> toJson() => {
    "valveGeographyArea": valveGeographyArea == null
        ? []
        : List<dynamic>.from(valveGeographyArea!.map((x) => x.toJson())),
    "liveMessage": liveMessage ?? {},
  };
}

 class Mapobject {
  int? objectId;
  double? sNo;
  String? name;
  String? objectName;
  List<Area>? area;
  int? status;
  int? percentage;


  Mapobject({
    this.objectId,
    this.sNo,
    this.name,
    this.objectName,
    this.area,
    this.status,
    this.percentage,
  });

  factory Mapobject.fromJson(Map<String, dynamic> json) => Mapobject(
    objectId: json["objectId"],
    sNo: json["sNo"]?.toDouble(),
    name: json["name"],
    objectName: json["objectName"],
    area: json["area"] == null
        ? []
        : List<Area>.from(
        json["area"].map((x) => Area.fromJson(x))),
    status: json["status"],
    percentage: json["percentage"],
  );

  Map<String, dynamic> toJson() => {
    "objectId": objectId,
    "sNo": sNo,
    "name": name,
    "objectName": objectName,
    "area": area == null
        ? []
        : List<dynamic>.from(area!.map((x) => x.toJson())),
    "status": status,
    "percentage": percentage,
  };
}

 class Area {
  double? latitude;
  double? longitude;

  Area({
    this.latitude,
    this.longitude,
  });

  factory Area.fromJson(Map<String, dynamic> json) => Area(
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "latitude": latitude,
    "longitude": longitude,
  };
}

 class Valve {
  final String name;
  late final List<LatLng> area;
  int status;
  int percentage;
  final int objectId;
  final double sNo;
  final String objectName;

  Valve({
    required this.name,
    required this.area,
    required this.status,
    required this.percentage,
    required this.objectId,
    required this.sNo,
    required this.objectName,
  });

  factory Valve.fromMapobject(
      Mapobject mapobject, Map<String, dynamic>? liveMessage) {
    return Valve(
      name: mapobject.name ?? '',
      area: mapobject.area
          ?.map((a) => LatLng(a.latitude ?? 0.0, a.longitude ?? 0.0))
          .toList() ??
          [],
      status: getValueOfStatus(mapobject.sNo?.toString() ?? '', liveMessage),
      percentage: getValuepercentage(mapobject.sNo?.toString() ?? '', liveMessage),
      objectId: mapobject.objectId ?? 0,
      sNo: mapobject.sNo ?? 0.0,
      objectName: mapobject.objectName ?? '',
    );
  }

  void updateStatus(int newStatus) {
    status = newStatus;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'area': area
        .map((point) => {
      'latitude': point.latitude,
      'longitude': point.longitude,
    })
        .toList(),
    'status': status,
    'percentage': percentage,
    'objectId': objectId,
    'sNo': sNo,
    'objectName': objectName,
  };

  factory Valve.fromJson(Map<String, dynamic> json) => Valve(
    name: json['name'],
    area: List<LatLng>.from((json['area'] as List).map(
            (point) => LatLng(point['latitude'], point['longitude']))),
    status: json['status'],
    percentage: json['percentage'],
    objectId: json['objectId'],
    sNo: json['sNo'].toDouble(),
    objectName: json['objectName'],
  );
}

 int getValueOfStatus(String serialNumber, Map<String, dynamic>? liveMessage) {
  try {
    if (liveMessage == null || liveMessage['cM'] == null) {
      return 0;
    }

    final cM = liveMessage['cM'] as Map<String, dynamic>;
    final data = cM['2402'] as String?;

    if (data == null || data.isEmpty) {
      return 0;
    }

    final values = data.split(';');
    for (final value in values) {
      if (value.startsWith(serialNumber)) {
        final parts = value.split(',');
        AppLog.log('getvalvestatus----$serialNumber--->${parts[1]}');
        return int.parse(parts[1]);
      }
    }

    return 0;
  } catch (e) {
    AppLog.log('Error parsing status for $serialNumber: $e');
    return 0;
  }
}
int getValuepercentage(String serialNumber, Map<String, dynamic>? liveMessage) {
  try {
    if (liveMessage == null || liveMessage['cM'] == null) {
      return 0;
    }

    final cM = liveMessage['cM'] as Map<String, dynamic>;
    final data = cM['2402'] as String?;

    if (data == null || data.isEmpty) {
      return 0;
    }

    final values = data.split(';');
    for (final value in values) {
      if (value.startsWith(serialNumber)) {
        AppLog.log('value:value--->$value');
        final parts = value.split(',');
        AppLog.log('getpercentage----$serialNumber--->${parts[2]}');
        return int.parse(parts[2]);
      }
    }

    return 0;
  } catch (e) {
    AppLog.log('Error parsing status for $serialNumber: $e');
    return 0;
  }
}

