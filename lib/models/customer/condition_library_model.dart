class ConditionLibraryModel {
  final ConditionLibrary cnLibrary;
  final DefaultData defaultData;

  ConditionLibraryModel({
    required this.cnLibrary,
    required this.defaultData,
  });

  factory ConditionLibraryModel.fromJson(Map<String, dynamic> json) {
    return ConditionLibraryModel(
      cnLibrary: ConditionLibrary.fromJson(json['conditionLibrary']),
      defaultData: DefaultData.fromJson(json['default']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conditionLibrary': cnLibrary.toJson(),
      'default': defaultData.toJson(),
    };
  }
}

class ConditionLibrary {
  List<Condition> condition;
  String controllerReadStatus;

  ConditionLibrary({
    required this.condition,
    required this.controllerReadStatus,
  });

  factory ConditionLibrary.fromJson(Map<String, dynamic> json) {
    return ConditionLibrary(
      condition: (json['condition'] as List<dynamic>?)
          ?.map((e) => Condition.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      controllerReadStatus: json['controllerReadStatus'] ?? "0",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "condition": condition.map((e) => e.toJson()).toList(),
      "controllerReadStatus": controllerReadStatus,
    };
  }
}

class Condition {
  int sNo;
  String name;
  bool status;
  String type;
  String rule;
  String component;
  String componentSNo;
  String parameter;
  String threshold;
  String value;
  String reason;
  String delayTime;
  String alertMessage;

  Condition({
    required this.sNo,
    required this.name,
    required this.status,
    required this.type,
    required this.rule,
    required this.component,
    required this.componentSNo,
    required this.parameter,
    required this.threshold,
    required this.value,
    required this.reason,
    required this.delayTime,
    required this.alertMessage,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      sNo: json['sNo'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? false,
      type: json['type'] ?? '',
      rule: json['rule'] ?? '',
      component: json['component'] ?? '',
      componentSNo: json['componentSNo'] ?? '0',
      parameter: json['parameter'] ?? '',
      threshold: json['threshold'] ?? '',
      value: json['value'] ?? '',
      reason: json['reason'] ?? '',
      delayTime: json['delayTime'] ?? '',
      alertMessage: json['alertMessage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "sNo": sNo,
      "name": name,
      "status": status,
      "type": type,
      "rule": rule,
      "component": component,
      "componentSNo": componentSNo,
      "parameter": parameter,
      "threshold": threshold,
      "value": value,
      "reason": reason,
      "delayTime": delayTime,
      "alertMessage": alertMessage,
    };
  }
}


class DefaultData {
  final int conditionLimit;
  final List<String> dropdown;
  final List<String> reason;
  final List<String> parameter;
  final List<String> action;
  List<Program> program;
  List<IrrigationLine> irrigationLine;
  List<Sequence> sequence;
  List<Sensor> sensors;
  List<SensorParameter> sensorParameter;
  List<String> programParameter;

  DefaultData({
    required this.conditionLimit,
    required this.dropdown,
    required this.reason,
    required this.parameter,
    required this.action,
    required this.program,
    required this.irrigationLine,
    required this.sequence,
    required this.sensors,
    required this.sensorParameter,
    required this.programParameter,
  });

  factory DefaultData.fromJson(Map<String, dynamic> json) {

    List<Program> programs = (json['program'] as List<dynamic>?)
        ?.map((e) => Program.fromJson(e)).toList() ?? [];

    if (programs.length > 1) {

      final hasPreDefault = programs.any((p) => p.name == 'Any Pre(Time/Qty) program');
      if (!hasPreDefault) {
        programs.insert(0,
          Program(
            sNo: 0,
            id: '0',
            name: 'Any Pre(Time/Qty) program',
            location: 'Global',
          ),
        );
      }

      final hasFrtDefault = programs.any((p) => p.name == 'Any fertilizer program');
      if (!hasFrtDefault) {
        programs.insert(0,
          Program(
            sNo: 0,
            id: '0',
            name: 'Any fertilizer program',
            location: 'Global',
          ),
        );
      }

      final hasIrrDefault = programs.any((p) => p.name == 'Any irrigation program');
      if (!hasIrrDefault) {
        programs.insert(0,
          Program(
            sNo: 0,
            id: '0',
            name: 'Any irrigation program',
            location: 'Global',
          ),
        );
      }
    }

    return DefaultData(
      conditionLimit: json['conditionLimit'] ?? 0,
      dropdown: List<String>.from(json['dropdown'] ?? []),
      reason: List<String>.from(json['reason'] ?? []),
      parameter: List<String>.from(json['parameter'] ?? []),
      action: List<String>.from(json['action'] ?? []),
      program: programs,

      irrigationLine: (json['irrigationLine'] as List<dynamic>?)
          ?.map((e) => IrrigationLine.fromJson(e))
          .toList() ??
          [],

      sequence: (json['sequence'] as List<dynamic>?)
          ?.map((e) => Sequence.fromJson(e))
          .toList() ??
          [],
      sensors: (json['sensors'] as List<dynamic>?)
          ?.map((e) => Sensor.fromJson(e))
          .toList() ??
          [],

      sensorParameter: (json['sensorParameter'] as List<dynamic>?)
          ?.map((e) => SensorParameter.fromJson(e))
          .toList() ??
          [],
      programParameter: _staticProgramParameters(),


    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conditionLimit': conditionLimit,
      'dropdown': dropdown,
      'reason': reason,
      'parameter': parameter,
      'action': action,
      'program': program,
      'sensorParameter': sensorParameter.map((e) => e.toJson()).toList(),
      'programParameter': programParameter,
    };
  }

  static List<String> _staticProgramParameters() {
    return ["Running", "Not Running", "Starting", "Ending"];
  }

}

class Program {
  int sNo;
  String id;
  String name;
  String location;

  Program({
    required this.sNo,
    required this.id,
    required this.name,
    required this.location,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      sNo: json['sNo'] ?? 0,
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'id': id,
      'name': name,
      'location': location,
    };
  }
}

class IrrigationLine {
  final int objectId;
  final double sNo;
  final String name;
  final double centralFertilization;
  final double localFertilization;

  IrrigationLine({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.centralFertilization,
    required this.localFertilization,
  });

  factory IrrigationLine.fromJson(Map<String, dynamic> json) {
    return IrrigationLine(
      objectId: json['objectId'] ?? 0,
      sNo: (json['sNo'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] ?? '',
      centralFertilization: (json['centralFertilization'] as num?)?.toDouble() ?? 0.0,
      localFertilization: (json['localFertilization'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
      'centralFertilization': centralFertilization,
      'localFertilization': localFertilization,
    };
  }
}

class Sequence {
  String sNo;
  String id;
  String name;
  String location;
  String locationName;

  Sequence({
    required this.sNo,
    required this.id,
    required this.name,
    required this.location,
    required this.locationName,
  });

  factory Sequence.fromJson(Map<String, dynamic> json) {
    return Sequence(
      sNo: json['sNo'] ?? '',
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      locationName: json['locationName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'id': id,
      'name': name,
      'location': location,
      'locationName': locationName,
    };
  }
}

class Sensor {
  int objectId;
  double sNo;
  String name;
  String objectName;

  Sensor({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      objectId: json['objectId'] ?? 0,
      sNo: (json['sNo'] ?? 0.0).toDouble(),
      name: json['name'] ?? '',
      objectName: json['objectName'] ?? '',
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

class SensorParameter {
  int objectId;
  String parameter;

  SensorParameter({
    required this.objectId,
    required this.parameter,
  });

  factory SensorParameter.fromJson(Map<String, dynamic> json) {
    return SensorParameter(
      objectId: json['objectId'],
      parameter: json['parameter'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "objectId": objectId,
      "parameter": parameter,
    };
  }
}