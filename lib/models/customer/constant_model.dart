import 'package:provider/provider.dart';
import '../../view_models/customer/customer_screen_controller_view_model.dart';

class UserConstant {
  final ConstantData constant;
  final DefaultData defaultData;

  UserConstant({
    required this.constant,
    required this.defaultData,
  });

  factory UserConstant.fromJson(context, Map<String, dynamic> json) {
    List<Map<String, dynamic>> configObject = [];
    List<Map<String, dynamic>> alarmList = [];

    if (json['default'] != null &&
        json['default']['configMaker'] != null &&
        json['default']['configMaker']['configObject'] != null) {

      configObject =  (json['default']['configMaker']['configObject'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      alarmList =  (json['default']['globalAlarm']as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

    } else {
      print("configObject is null or missing");
    }

    return UserConstant(
      constant: ConstantData.fromJson(context, json['constant'], configObject, alarmList),
      defaultData: DefaultData.fromJson(json['default']),
    );
  }
}

class ConstantData {
  final String controllerReadStatus;
  final List<GeneralMenu> generalMenu;
  final List<ValveData>? valveList;
  final List<Pump>? pumpList;
  final List<MainValveData>? mainValveList;
  final List<IrrigationLine>? irrigationLineList;
  final List<WaterMeterModel>? waterMeterList;
  final List<AllAlarmModel>? criticalAlarm;
  final List<GlobalAlarmModel>? globalAlarm;
  final List<LevelSensor>? levelSensor;
  final List<MoistureSensor>? moistureSensor;
  final List<ConstantFertilizerSite>? fertilization;


  ConstantData({
    required this.controllerReadStatus,
    required this.generalMenu,
    required this.valveList,
    required this.pumpList,
    required this.mainValveList,
    required this.irrigationLineList,
    required this.waterMeterList,
    required this.criticalAlarm,
    required this.globalAlarm,
    required this.levelSensor,
    required this.moistureSensor,
    required this.fertilization,
  });

  factory ConstantData.fromJson(context, Map<String, dynamic> jsonConstant, List<Map<String, dynamic>> jsonConfigObject, List<Map<String, dynamic>> alarm) {


    List<Map<String, dynamic>>  irrigationLineList = jsonConfigObject
        .where((obj) => obj['objectId'] == 2)
        .toList();

    List<Map<String, dynamic>> valveDataList = jsonConfigObject
        .where((obj) => obj['objectId'] == 13)
        .toList();

    List<Map<String, dynamic>> pumpDataList = jsonConfigObject
        .where((obj) => obj['objectId'] == 5)
        .toList();

    List<Map<String, dynamic>> mainValveDataList = jsonConfigObject
        .where((obj) => obj['objectId'] == 14)
        .toList();

    List<Map<String, dynamic>>  waterMeterDataList = jsonConfigObject
        .where((obj) => obj['objectId'] == 22)
        .toList();

    List<AllAlarmModel> criticalAlarm = (jsonConstant['criticalAlarm'] as List<dynamic>?)
        ?.map((cAlarm) => AllAlarmModel.fromMap(cAlarm))
        .toList() ?? [];

    List<GlobalAlarmModel> globalAlarm = (jsonConstant['globalAlarm'] as List<dynamic>?)
        ?.map((cAlarm) => GlobalAlarmModel.fromMap(cAlarm))
        .toList() ?? [];


    if (criticalAlarm.isEmpty) {
      for (var alarmItem in alarm) {
        criticalAlarm.add(AllAlarmModel.fromMap({
          "sNo": alarmItem['sNo'],
          "name": alarmItem['title'],
          "scanTime": '00:00:00',
          "unit": "%",
          "alarmOnStatus": 'Do Nothing',
          "resetAfterIrrigation": "No",
          "autoResetDuration": '00:00:00',
          "threshold": "0",
          "type": "Normal"
        }));
        criticalAlarm.add(AllAlarmModel.fromMap({
          "sNo": alarmItem['sNo'],
          "name": alarmItem['title'],
          "scanTime": '00:00:00',
          "unit": "%",
          "alarmOnStatus": 'Do Nothing',
          "resetAfterIrrigation": "No",
          "autoResetDuration": '00:00:00',
          "threshold": "0",
          "type": "Critical"
        }));

        globalAlarm.add(GlobalAlarmModel.fromMap({
          "name": alarmItem['title'],
          "value": false,
        }));
      }
    }

    List<Map<String, dynamic>>  levelSensorDataList = jsonConfigObject
        .where((obj) => obj['objectId'] == 26)
        .toList();

    List<Map<String, dynamic>>  moistureSensorDataList = jsonConfigObject
        .where((obj) => obj['objectId'] == 25)
        .toList();

    final viewModel = Provider.of<CustomerScreenControllerViewModel>(context, listen: false);

    List<Map<String, dynamic>> fertilizerData = viewModel
        .mySiteList
        .data[viewModel.sIndex]
        .master[viewModel.mIndex]
        .irrigationLine[viewModel.lIndex]
        .centralFertilizerSite! as List<Map<String, dynamic>>;


    List<ConstantFertilizerSite> fertilizerSite = (jsonConstant['fertilization'] != null &&
        jsonConstant['fertilization'] is List && (jsonConstant['fertilization'] as List).isNotEmpty)
        ? (jsonConstant['fertilization'] as List)
        .map((frtSite) => ConstantFertilizerSite.fromJson(frtSite))
        .toList()
        : (fertilizerData.isNotEmpty
        ? fertilizerData.map((site) => ConstantFertilizerSite.fromJson(site)).toList()
        : []);

    return ConstantData(
      controllerReadStatus: jsonConstant['controllerReadStatus'] ?? '0',
      generalMenu: (jsonConstant['general'] is List && (jsonConstant['general'] as List).isNotEmpty)
          ? (jsonConstant['general'] as List<dynamic>)
          .map((general) => GeneralMenu.fromJson(general as Map<String, dynamic>))
          .toList()
          : [
        GeneralMenu.fromJson({"sNo": 1, "title": "Number of Programs", "widgetTypeId": 1, "value": "0"}),
        GeneralMenu.fromJson({"sNo": 2, "title": "Number of Valve Groups", "widgetTypeId": 1, "value": "0"}),
        GeneralMenu.fromJson({"sNo": 3, "title": "Number of Conditions", "widgetTypeId": 1, "value": "0"}),
        GeneralMenu.fromJson({"sNo": 4, "title": "Run List Limit", "widgetTypeId": 1, "value": "0"}),
        GeneralMenu.fromJson({"sNo": 5, "title": "Fertilizer Leakage Limit", "widgetTypeId": 1, "value": "0"}),
        GeneralMenu.fromJson({"sNo": 6, "title": "Reset Time", "widgetTypeId": 3, "value": "00:00:00"}),
        GeneralMenu.fromJson({"sNo": 7, "title": "No Pressure Delay", "widgetTypeId": 3, "value": "00:00:00"}),
        GeneralMenu.fromJson({"sNo": 8, "title": "Common dosing coefficient", "widgetTypeId": 1, "value": "0"}),
        GeneralMenu.fromJson({"sNo": 9, "title": "Water pulse before dosing", "widgetTypeId": 2, "value": false}),
        GeneralMenu.fromJson({"sNo": 10, "title": "Pump on after valve on", "widgetTypeId": 2, "value": false}),
        GeneralMenu.fromJson({"sNo": 11, "title": "Lora Key 1", "widgetTypeId": 1, "value": "0"}),
        GeneralMenu.fromJson({"sNo": 12, "title": "Lora Key 2", "widgetTypeId": 1, "value": "0"}),
      ],

      valveList: (jsonConstant['valve'] is List && (jsonConstant['valve'] as List).isNotEmpty)
          ? (jsonConstant['valve'] as List<dynamic>)
          .map((val) => ValveData.fromJson(val as Map<String, dynamic>))
          .toList()
          : (valveDataList.isNotEmpty
          ? valveDataList.map((val) => ValveData.fromJson(val)).toList()
          : []),

      pumpList: (jsonConstant['pump'] as List<dynamic>?)?.isNotEmpty == true
          ? (jsonConstant['pump'] as List<dynamic>).map((pmp) => Pump.fromJson(pmp)).toList()
          : pumpDataList.map((pmp) => Pump.fromJson(pmp)).toList(),

      mainValveList: (jsonConstant['mainValve'] as List<dynamic>?)?.isNotEmpty == true
          ? (jsonConstant['mainValve'] as List<dynamic>).map((mv) => MainValveData.fromJson(mv)).toList()
          : mainValveDataList.map((mv) => MainValveData.fromJson(mv)).toList(),

      irrigationLineList: (jsonConstant['irrigationLine'] as List<dynamic>?)?.isNotEmpty == true
          ? (jsonConstant['irrigationLine'] as List<dynamic>).map((ir) => IrrigationLine.fromJson(ir)).toList()
          : irrigationLineList.map((ir) => IrrigationLine.fromJson(ir)).toList(),

      waterMeterList: (jsonConstant['waterMeter'] as List<dynamic>?)?.isNotEmpty == true
          ? (jsonConstant['waterMeter'] as List<dynamic>).map((ir) => WaterMeterModel.fromJson(ir)).toList()
          : waterMeterDataList.map((ir) => WaterMeterModel.fromJson(ir)).toList(),

      criticalAlarm : criticalAlarm,

      globalAlarm : globalAlarm,

      levelSensor: (jsonConstant['levelSensor'] as List<dynamic>?)?.isNotEmpty == true
          ? (jsonConstant['levelSensor'] as List<dynamic>).map((pmp) => LevelSensor.fromJson(pmp)).toList()
          : levelSensorDataList.map((pmp) => LevelSensor.fromJson(pmp)).toList(),

      moistureSensor: (jsonConstant['moistureSensor'] as List<dynamic>?)?.isNotEmpty == true
          ? (jsonConstant['moistureSensor'] as List<dynamic>).map((pmp) => MoistureSensor.fromJson(pmp)).toList()
          : moistureSensorDataList.map((pmp) => MoistureSensor.fromJson(pmp)).toList(),

      fertilization : fertilizerSite,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'controllerReadStatus': controllerReadStatus,
      'general': generalMenu.map((e) => e.toJson()).toList(),
      'valveList': valveList?.map((e) => e.toJson()).toList() ?? [],
      'pumpList': pumpList?.map((e) => e.toJson()).toList() ?? [],
      'mainValve': mainValveList?.map((e) => e.toJson()).toList() ?? [],
      'irrigationLine': irrigationLineList?.map((e) => e.toJson()).toList() ?? [],
      'waterMeter': waterMeterList?.map((e) => e.toJson()).toList() ?? [],
      "criticalAlarm": criticalAlarm?.map((e) => e.toJson()).toList() ?? [],
      "globalAlarm": globalAlarm?.map((e) => e.toJson()).toList() ?? [],
      "levelSensor": levelSensor?.map((e) => e.toJson()).toList() ?? [],
      "moistureSensor": moistureSensor?.map((e) => e.toJson()).toList() ?? [],
      "fertilization": fertilization?.map((e) => e.toJson()).toList() ?? [],
    };
  }

}

class GeneralMenu {
  final int sNo;
  final String title;
  final int widgetTypeId;
  dynamic value;

  GeneralMenu({
    required this.sNo,
    required this.title,
    required this.widgetTypeId,
    required this.value,
  });

  factory GeneralMenu.fromJson(Map<String, dynamic> json) {
    return GeneralMenu(
      sNo: json['sNo'] as int,
      title: json['title'] as String,
      widgetTypeId: json['widgetTypeId'] as int,
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'title': title,
      'widgetTypeId': widgetTypeId,
      'value': value,
    };
  }
}

class ValveData {
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  final String type;
  final int? controllerId;
  final int? connectionNo;
  final int? count;
  final String? connectedObject;
  final String? siteMode;
  String txtValue;
  String duration;

  ValveData({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.type,
    this.controllerId,
    this.connectionNo,
    this.count,
    this.connectedObject,
    this.siteMode,
    required this.txtValue,
    required this.duration,
  });

  factory ValveData.fromJson(Map<String, dynamic> json) {
    return ValveData(
      objectId: json['objectId'],
      sNo: (json['sNo'] as num).toDouble(),
      name: json['name'],
      objectName: json['objectName'],
      type: json['type'],
      controllerId: json['controllerId'],
      connectionNo: json['connectionNo'],
      count: json['count'],
      connectedObject: json['connectedObject'],
      siteMode: json['siteMode'],
      txtValue: json.containsKey('txtValue') ? json['txtValue'] : "0",
      duration: json.containsKey('duration') ? json['duration'] : "00:00:00",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
      'objectName': objectName,
      'type': type,
      'controllerId': controllerId,
      'connectionNo': connectionNo,
      'count': count,
      'connectedObject': connectedObject,
      'siteMode': siteMode,
      'txtValue': txtValue,
      'duration': duration,
    };
  }
}

class MainValveData {
  final int objectId;
  final double sNo;
  final String name;
  final int? connectionNo;
  final String objectName;
  final String? type;
  final int? controllerId;
  final int? count;
  String duration;
  String delay;

  MainValveData({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.connectionNo,
    required this.objectName,
    required this.type,
    required this.controllerId,
    this.count,
    required this.duration,
    this.delay = "No delay",
  });

  factory MainValveData.fromJson(Map<String, dynamic> json) => MainValveData(
    objectId: json["objectId"],
    sNo: (json["sNo"] as num).toDouble(),
    name: json["name"],
    connectionNo: json["connectionNo"]??0,
    objectName: json["objectName"],
    type: json["type"],
    controllerId: json["controllerId"]??0,
    count: json["count"]??0,
    delay: json["delay"] != null && json["delay"].isNotEmpty ? json["delay"] : "No delay",
    duration: json.containsKey('duration') ? json['duration'] : "00:00:00",

  );

  Map<String, dynamic> toJson() => {
    "objectId": objectId,
    "sNo": sNo,
    "name": name,
    "connectionNo": connectionNo,
    "objectName": objectName,
    "type": type,
    "controllerId": controllerId,
    "count": count,
    "duration": duration,
    "delay": delay,
  };
}

class Pump {
  final int objectId;
  final double sNo;
  final String name;
 // final String objectName;
  final String type;
  final int? controllerId;
  final int? connectionNo;
  final int? count;
  final String? connectedObject;
  final String? siteMode;
  bool pumpStation;
  bool controlGem;

  Pump({
    required this.objectId,
    required this.sNo,
    required this.name,
   // required this.objectName,
    required this.type,
    this.controllerId,
    this.connectionNo,
    this.count,
    this.connectedObject,
    this.siteMode,
    required this.pumpStation,
    required this.controlGem,
  });

  factory Pump.fromJson(Map<String, dynamic> json) {
    return Pump(
      objectId: json['objectId'],
      sNo: (json['sNo'] as num).toDouble(),
      name: json['name'],
     // objectName: json['objectName'],
      type: json['type'],
      controllerId: json['controllerId'],
      connectionNo: json['connectionNo'],
      count: json['count'],
      connectedObject: json['connectedObject'],
      siteMode: json['siteMode'],
      pumpStation: json.containsKey('pumpStation') ? json['pumpStation'] : false,
      controlGem: json.containsKey('controlGem') ? json['controlGem'] : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
     // 'objectName': objectName,
      'type': type,
      'controllerId': controllerId,
      'connectionNo': connectionNo,
      'count': count,
      'connectedObject': connectedObject,
      'siteMode': siteMode,
      'pumpStation': pumpStation,
      'controlGem': controlGem,
    };
  }
}

class IrrigationLine {
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  final String type;
  final dynamic connectionNo;
  final dynamic controllerId;
  final dynamic count;
  final dynamic connectedObject;
  final dynamic siteMode;
  final double location;
  String lowFlowDelay;
  String highFlowDelay;
  String lowFlowAction;
  String highFlowAction;

  IrrigationLine({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.type,
    this.connectionNo,
    this.controllerId,
    this.count,
    this.connectedObject,
    this.siteMode,
    required this.location,
    required this.highFlowDelay,
    required this.lowFlowDelay,
    required this.lowFlowAction,
    required this.highFlowAction,
  });

  factory IrrigationLine.fromJson(Map<String, dynamic> json) {
    return IrrigationLine(
      objectId: json['objectId'] ?? 0,
      sNo: (json['sNo'] as num).toDouble(),
      name: json['name'] ?? '',
      objectName: json['objectName'] ?? '',
      type: json['type'] ?? '-',
      connectionNo: json['connectionNo'],
      controllerId: json['controllerId'],
      count: json['count'],
      connectedObject: json['connectedObject'],
      siteMode: json['siteMode'],
      location: (json['location'] as num).toDouble(),
      lowFlowDelay: json.containsKey('lowFlowDelay') ? json['lowFlowDelay'] : "00:00:00",
      highFlowDelay: json.containsKey('highFlowDelay') ? json['highFlowDelay'] : "00:00:00",
      lowFlowAction: json["lowFlowAction"] != null && json["lowFlowAction"].isNotEmpty ? json["lowFlowAction"] : "Ignore",
      highFlowAction: json["lowFlowAction"] != null && json["lowFlowAction"].isNotEmpty ? json["lowFlowAction"] : "Ignore",


    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
      'objectName': objectName,
      'type': type,
      'connectionNo': connectionNo,
      'controllerId': controllerId,
      'count': count,
      'connectedObject': connectedObject,
      'siteMode': siteMode,
      'location': location,
      'highFlowDelay': highFlowDelay,
      'lowFlowDelay': lowFlowDelay,
      'lowFlowAction': lowFlowAction,
      'highFlowAction': highFlowAction,
    };

  }
}

class WaterMeterModel {
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  final String type;
  final dynamic connectionNo;
  final dynamic controllerId;
  final dynamic count;
  final dynamic connectedObject;
  final dynamic siteMode;
  final double location;
  String radio;

  WaterMeterModel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.type,
    this.connectionNo,
    this.controllerId,
    this.count,
    this.connectedObject,
    this.siteMode,
    required this.location,
    required this.radio,
  });

  factory WaterMeterModel.fromJson(Map<String, dynamic> json) {
    return WaterMeterModel(
      objectId: json['objectId'] ?? 0,
      sNo: (json['sNo'] as num).toDouble(),
      name: json['name'] ?? '',
      objectName: json['objectName'] ?? '',
      type: json['type'] ?? '-',
      connectionNo: json['connectionNo'],
      controllerId: json['controllerId'],
      count: json['count'],
      connectedObject: json['connectedObject'],
      siteMode: json['siteMode'],
      location: (json['location'] as num).toDouble(),
      radio: json.containsKey('radio') ? json['radio'] : "0",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
      'objectName': objectName,
      'type': type,
      'connectionNo': connectionNo,
      'controllerId': controllerId,
      'count': count,
      'connectedObject': connectedObject,
      'siteMode': siteMode,
      'location': location,
      'radio': radio,
    };

  }
}

class AllAlarmModel {
  String name;
  String unit;
  String scanTime;
  String alarmOnStatus;
  String resetAfterIrrigation;
  String autoResetDuration;
  String threshold;
  String type;

  AllAlarmModel({
    required this.name,
    required this.unit,
    required this.scanTime,
    required this.alarmOnStatus,
    required this.resetAfterIrrigation,
    required this.autoResetDuration,
    required this.threshold,
    required this.type,
  });

  factory AllAlarmModel.fromMap(Map<String, dynamic> json) {
    return AllAlarmModel(
      name: json['name'],
      unit: json['unit'],
      scanTime: json['scanTime'],
      alarmOnStatus: json['alarmOnStatus'],
      resetAfterIrrigation: json['resetAfterIrrigation'],
      autoResetDuration: json['autoResetDuration'],
      threshold: json['threshold'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "scanTime": scanTime,
      "alarmOnStatus": alarmOnStatus,
      "resetAfterIrrigation": resetAfterIrrigation,
      "autoResetDuration": autoResetDuration,
      "threshold": threshold,
      "unit": unit,
      "type": type,
    };
  }


}

class GlobalAlarmModel {
  String name;
  bool value;

  GlobalAlarmModel({
    required this.name,
    required this.value,
  });

  factory GlobalAlarmModel.fromMap(Map<String, dynamic> json) {
    return GlobalAlarmModel(
      name: json['name'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "value": value,
    };
  }

}

class LevelSensor {
  int objectId;
  int sensorId;
  double sNo;
  String name;
  int connectionNo;
  String objectName;
  String type;
  int controllerId;
  String highLow;
  String units;
  String base;
  double min;
  double max;
  double height;

  LevelSensor({
    required this.objectId,
    required this.sensorId,
    required this.sNo,
    required this.name,
    required this.connectionNo,
    required this.objectName,
    required this.type,
    required this.controllerId,
    required this.highLow,

    required this.units,
    required this.base,
    required this.min,
    required this.max,
    required this.height,
  });

  factory LevelSensor.fromJson(Map<String, dynamic> json) {
    return LevelSensor(
      objectId: (json['objectId'] as num?)?.toInt() ?? 0,
      sensorId: (json['sensorId'] as num?)?.toInt() ?? 0,
      sNo: (json['sNo'] as num?)?.toDouble() ?? 0.0,
      name: json['name']?.toString() ?? '',
      connectionNo: (json['connectionNo'] as num?)?.toInt() ?? 0,
      objectName: json['objectName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      controllerId: (json['controllerId'] as num?)?.toInt() ?? 0,

      highLow: json.containsKey('highLow') ? json['highLow'] : '-',
      units: json.containsKey('units') ? json['units'] : 'Bar',
      base: json.containsKey('base') ? json['base'] : 'Current',
      min: json.containsKey('min') ? json['min'] : 0.00,
      max: json.containsKey('max') ? json['max'] : 0.00,
      height: json.containsKey('height') ? json['height'] : 0.00,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sensorId': sensorId,
      'sNo': sNo,
      'name': name,
      'connectionNo': connectionNo,
      'objectName': objectName,
      'type': type,
      'controllerId': controllerId,

      'highLow': highLow,
      'units': units,
      'base': base,
      'min': min,
      'max': max,
      'height': height,
    };
  }
}

class MoistureSensor {
  int objectId;
  int objectIds;
  double sNo;
  final String name;
  final int connectionNo;
  final String objectName;
  final String type;
  final int controllerId;
  final int? count;
  final Map<String, dynamic> connectedObject;
  final dynamic siteMode;
  final List<dynamic> valves;
  String highLow;
  String units;
  String base;
  double min;
  double max;

  MoistureSensor({
    required this.objectId,
    required this.objectIds,
    required this.sNo,
    required this.name,
    required this.connectionNo,
    required this.objectName,
    required this.type,
    required this.controllerId,
    this.count,
    required this.connectedObject,
    this.siteMode,
    required this.valves,
    required this.highLow,
    required this.units,
    required this.base,
    required this.min,
    required this.max,
  });

  factory MoistureSensor.fromJson(Map<String, dynamic> json) {
    return MoistureSensor(
      objectId: json['objectId'] ?? 0,
      objectIds: json['objectIds'] ?? 0,
      sNo: (json['sNo'] as num?)?.toDouble() ?? 0.0,
      name: json['name']?.toString() ?? '',
      connectionNo: json['connectionNo'] ?? 0,
      objectName: json['objectName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      controllerId: json['controllerId'] ?? 0,
      count: json['count'] as int? ?? 0,
      connectedObject: json['connectedObject'] is Map<String, dynamic>
          ? json['connectedObject'] as Map<String, dynamic>
          : {},
      siteMode: json['siteMode']?.toString() ?? '',
      valves: json['valves'] is List ? List.from(json['valves']) : [],

      highLow: json.containsKey('highLow') ? json['highLow'] : '-',
      units: json.containsKey('units') ? json['units'] : 'Bar',
      base: json.containsKey('base') ? json['base'] : 'Current',
      min: json.containsKey('min') ? json['min'] : 0.00,
      max: json.containsKey('max') ? json['max'] : 0.00,
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'objectIds': objectIds,
      'sNo': sNo,
      'name': name,
      'connectionNo': connectionNo,
      'objectName': objectName,
      'type': type,
      'controllerId': controllerId,
      'count': count,
      'connectedObject': connectedObject,
      'siteMode': siteMode,
      'valves': valves,
      'highLow': highLow,
      'units': units,
      'base': base,
      'min': min,
      'max': max,
    };
  }
}

class ConstantFertilizerSite {
  final int objectId;
  final double sNo;
  final String name;
  final List<Channel> channel;
  List<EcPh> ecSensor;
  List<EcPh> phSensor;

  String minimalOnTime;
  String minimalOffTime;
  String boosterDelay;

  ConstantFertilizerSite({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.channel,
    required this.ecSensor,
    required this.phSensor,

    required this.minimalOnTime,
    required this.minimalOffTime,
    required this.boosterDelay,
  });

  factory ConstantFertilizerSite.fromJson(Map<String, dynamic> json) {
    return ConstantFertilizerSite(
      objectId: json['objectId'],
      sNo: json['sNo'].toDouble(),
      name: json['name'],
      channel: (json['channel'] as List).map((e) => Channel.fromJson(e)).toList(),
      ecSensor: (json['ec'] as List).map((e) => EcPh.fromJson(e)).toList(),
      phSensor: (json['ph'] as List).map((e) => EcPh.fromJson(e)).toList(),

      minimalOnTime: json.containsKey('minimalOnTime') ? json['minimalOnTime'] : "00:00:00",
      minimalOffTime: json.containsKey('minimalOffTime') ? json['minimalOffTime'] : "00:00:00",
      boosterDelay: json.containsKey('boosterDelay') ? json['boosterDelay'] : "00:00:00",

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
      'channel': channel.map((e) => e.toJson()).toList(),
      'ec': ecSensor.map((e) => e.toJson()).toList(),
      'ph': phSensor.map((e) => e.toJson()).toList(),
      'minimalOnTime': minimalOnTime,
      'minimalOffTime': minimalOffTime,
      'boosterDelay': boosterDelay,
    };
  }


}

class Channel {
  final int objectId;
  final double sNo;
  final String name;

  String ratioTxtValue;
  String pulseTxtValue;
  String nmlFlowTxtValue;
  String injectorMode;


  Channel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.ratioTxtValue,
    required this.pulseTxtValue,
    required this.nmlFlowTxtValue,
    required this.injectorMode,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      objectId: json['objectId'],
      sNo: json['sNo'].toDouble(),
      name: json['name'],
      ratioTxtValue: json.containsKey('ratioTxtValue') ? json['ratioTxtValue'] : "0",
      pulseTxtValue: json.containsKey('pulseTxtValue') ? json['pulseTxtValue'] : "0",
      nmlFlowTxtValue: json.containsKey('nmlFlowTxtValue') ? json['nmlFlowTxtValue'] : "0",
      injectorMode: json.containsKey('injectorMode') ? json['injectorMode'] : "Concentration",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
      'ratioTxtValue': ratioTxtValue,
      'pulseTxtValue': pulseTxtValue,
      'nmlFlowTxtValue': nmlFlowTxtValue,
      'injectorMode': injectorMode,
    };
  }
}

class EcPh {
  final int objectId;
  final double sNo;
  final String name;

  String controlCycle;
  String delta;
  String fineTuning;
  String coarseTuning;
  String deadband;
  String integ;
  String controlSensor;
  String avgFiltSpeed;
  String percentage;


  EcPh({
    required this.objectId,
    required this.sNo,
    required this.name,

    required this.controlCycle,
    required this.delta,
    required this.fineTuning,
    required this.coarseTuning,
    required this.deadband,
    required this.integ,
    required this.controlSensor,
    required this.avgFiltSpeed,
    required this.percentage,

  });

  factory EcPh.fromJson(Map<String, dynamic> json) {
    return EcPh(
      objectId: json['objectId'],
      sNo: json['sNo'].toDouble(),
      name: json['name'],

      controlCycle: json.containsKey('controlCycle') ? json['controlCycle'] : "00:00:00",
      delta: json.containsKey('delta') ? json['delta'] : "0",
      fineTuning: json.containsKey('fineTuning') ? json['fineTuning'] : "0",
      coarseTuning: json.containsKey('coarseTuning') ? json['coarseTuning'] : "0",
      deadband: json.containsKey('deadband') ? json['deadband'] : "0",
      integ: json.containsKey('integ') ? json['integ'] : "00:00:00",
      controlSensor: json.containsKey('controlSensor') ? json['controlSensor'] : "Average",
      avgFiltSpeed: json.containsKey('avgFiltSpeed') ? json['avgFiltSpeed'] : "0",
      percentage: json.containsKey('percentage') ? json['percentage'] : "0",

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,

      'controlCycle': controlCycle,
      'delta': delta,
      'fineTuning': fineTuning,
      'coarseTuning': coarseTuning,
      'deadband': deadband,
      'integ': integ,
      'controlSensor': controlSensor,
      'avgFiltSpeed': avgFiltSpeed,
      'percentage': percentage,
    };
  }

}


class DefaultData {
  final List<Alarm> alarms;
  final List<ConstantMenu> constantMenus;

  DefaultData({
    required this.alarms,
    required this.constantMenus,
  });

  factory DefaultData.fromJson(Map<String, dynamic> json) {
    return DefaultData(
      alarms: (json['alarmType'] as List).map((e) => Alarm.fromJson(e)).toList(),
      constantMenus: (json['constantMenu'] as List)
          .map((e) => ConstantMenu.fromJson(e)).toList(),
    );
  }
}

class Alarm {
  final int sNo;
  final String name;
  final String unit;

  Alarm({
    required this.sNo,
    required this.name,
    required this.unit,
  });

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      sNo: json['sNo'],
      name: json['title'],
      unit: json['unit'],
    );
  }
}

class ConstantMenu {
  final int dealerDefinitionId;
  final String parameter;
  bool isSelected;

  ConstantMenu({
    required this.dealerDefinitionId,
    required this.parameter,
    this.isSelected = false,
  });

  factory ConstantMenu.fromJson(Map<String, dynamic> json) {
    return ConstantMenu(
      dealerDefinitionId: json['dealerDefinitionId'],
      parameter: json['parameter'],
    );
  }
}
