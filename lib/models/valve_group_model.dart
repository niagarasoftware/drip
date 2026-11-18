import 'dart:convert';
Groupdata groupdataFromJson(String str) => Groupdata.fromJson(json.decode(str));

String groupdataToJson(Groupdata data) => json.encode(data.toJson());

class Groupdata {
  int? code;
  String? message;
  valveGroupData? data;

  Groupdata({
    this.code,
    this.message,
    this.data,
  });

  factory Groupdata.fromJson(Map<String, dynamic> json) => Groupdata(
    code: json["code"],
    message: json["message"],
    data: json["data"] == null ? null : valveGroupData.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "data": data?.toJson(),
  };
}


class valveGroupData {
  final List<ValveGroup>? valveGroup;
  final Default defaultData;

  valveGroupData({required this.valveGroup, required this.defaultData});

  factory valveGroupData.fromJson(Map<String, dynamic> json) {
    return valveGroupData(
      valveGroup: json['valveGroup'] == null
          ? null
          : List<ValveGroup>.from(
          json['valveGroup'].map((x) => ValveGroup.fromJson(x))),

      defaultData: Default.fromJson(json['default']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valveGroup': valveGroup?.map((x) => x.toJson()).toList() ?? [],
      'default': defaultData.toJson(),
    };
  }
}

class ValveGroup {
  final String groupID;
  final int objectId;
  final String groupName;
  final String irrigationLineName;
  final double sNo;
  final String name;
  final String objectName;
  final List<Valve> valve;

  ValveGroup({
    required this.groupID,
    required this.objectId,
    required this.groupName,
    required this.irrigationLineName,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.valve,
  });

  factory ValveGroup.fromJson(Map<String, dynamic> json) {
    return ValveGroup(
      groupID: json['groupId'],
      objectId: json['objectId'],
      groupName: json['groupName'],
      irrigationLineName: json['irrigationLineName'],
      sNo: json['sNo'].toDouble(),
      name: json['name'],
      objectName: json['objectName'],
      valve: List<Valve>.from(json['valve'].map((x) => Valve.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupID,
      'objectId': objectId,
      'groupName': groupName,
      'irrigationLineName': irrigationLineName,
      'sNo': sNo,
      'name': name,
      'objectName': objectName,
      'valve': valve.map((x) => x.toJson()).toList(),
    };
  }
}

class Valve {
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;

  Valve({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
  });

  factory Valve.fromJson(Map<String, dynamic> json) {
    return Valve(
      objectId: json['objectId'],
      sNo: json['sNo'].toDouble(),
      name: json['name'],
      objectName: json['objectName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
      'objectName': objectName,
    };
  }
}

class Default {
  final int valveGroupLimit;
  final List<IrrigationLine> irrigationLine;

  Default({required this.valveGroupLimit, required this.irrigationLine});

  factory Default.fromJson(Map<String, dynamic> json) {
    return Default(
      valveGroupLimit: json['valveGroupLimit'],
      irrigationLine: List<IrrigationLine>.from(
          json['irrigationLine'].map((x) => IrrigationLine.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valveGroupLimit': valveGroupLimit,
      'irrigationLine': irrigationLine.map((x) => x.toJson()).toList(),
    };
  }
}

class IrrigationLine {
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  final List<Valve> valve;

  IrrigationLine({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.valve,
  });

  factory IrrigationLine.fromJson(Map<String, dynamic> json) {
    return IrrigationLine(
      objectId: json['objectId'],
      sNo: json['sNo'].toDouble(),
      name: json['name'],
      objectName: json['objectName'],
      valve: List<Valve>.from(json['valve'].map((x) => Valve.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
      'objectName': objectName,
      'valve': valve.map((x) => x.toJson()).toList(),
    };
  }
}