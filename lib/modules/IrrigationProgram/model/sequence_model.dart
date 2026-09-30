import 'package:intl/intl.dart';
import 'package:oro_drip_irrigation/modules/config_maker/model/device_object_model.dart';

class SequenceModel {
  List<dynamic> sequence;
  Default defaultData;

  SequenceModel({required this.sequence, required this.defaultData});

  factory SequenceModel.fromJson(Map<String, dynamic> json) {
    return SequenceModel(
      sequence: json['data']['sequence'] ?? [],
      defaultData: Default.fromJson(json['data']['default']),
    );
  }

  Map<String, dynamic> toJson() {
    return {"sequence": sequence, "defaultData": defaultData.toJson()};
  }

  dynamic toMqtt() {
    return sequence;
  }
}

class Default {
  bool startTogether;
  bool longSequence;
  bool reuseValve;
  bool namedGroup;
  // List<Line> line;
  List<ValveGroup> group;
  // List<Valve> agitator;

  Default(
      {required this.startTogether,
        // required this.line,
        required this.group,
        required this.longSequence,
        required this.reuseValve,
        required this.namedGroup,
        // required this.agitator
      });

  factory Default.fromJson(Map<String, dynamic> json) {
    List<ValveGroup> groupList = List<ValveGroup>.from(json['valveGroupList'].map((x) => ValveGroup.fromJson(x)));

    return Default(
      startTogether: json['startTogether'],
      longSequence: json['longSequence'],
      reuseValve: json['reuseValve'],
      namedGroup: json['valveGroup'] ?? false,
      // line: lineList,
      group: groupList,
      // agitator: agitatorList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "startTogether": startTogether,
      "longSequence": longSequence,
      "reuseValve": reuseValve,
      "namedGroup": namedGroup,
      // "line": line.map((e) => e.toJson()).toList(),
      "group": group.map((e) => e.toJson()).toList(),
      // "agitator": agitator.map((e) => e.toJson()).toList(),
    };
  }
}

class ValveGroup {
  String id;
  String name;
  List<DeviceObjectModel> valve;

  ValveGroup(
      {
        required this.id,
        required this.name,
        required this.valve});

  factory ValveGroup.fromJson(Map<String, dynamic> json) {
    // print("json in the ValveGroup : ${json}");
    var valveList = json['valve'] as List<dynamic>?;

    List<DeviceObjectModel> valves = valveList != null
        ? valveList
        .map((e) => DeviceObjectModel.fromJson(e as Map<String, dynamic>))
        .toList()
        : [];

    return ValveGroup(
      id: json['groupId'],
      name: json['groupName'],
      valve: valves,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "valve": valve.map((e) => e.toJson()).toList(),
    };
  }
}

class SampleScheduleModel {
  ScheduleAsRunListModel scheduleAsRunList;
  ScheduleByDaysModel scheduleByDays;
  DayCountSchedule dayCountSchedule;
  String selected;
  DefaultModel defaultModel;

  SampleScheduleModel({
    required this.scheduleAsRunList,
    required this.scheduleByDays,
    required this.dayCountSchedule,
    required this.selected,
    required this.defaultModel,
  });

  factory SampleScheduleModel.fromJson(Map<String, dynamic> json) {
    return SampleScheduleModel(
      scheduleAsRunList: ScheduleAsRunListModel.fromJson(
          json['data']['schedule']['scheduleAsRunList']
      ),
      scheduleByDays: ScheduleByDaysModel.fromJson(
          json['data']['schedule']['scheduleByDays']
      ),
      dayCountSchedule: DayCountSchedule.fromJson(
        json['data']['schedule']['dayCountSchedule'] ??
            {
              "schedule": { "onTime": "00:00:00", "interval": "00:00:00", "shouldLimitCycles": false, "noOfCycles": "1"}
            },
      ),
      selected: json['data']['schedule']['selected'],
      defaultModel: DefaultModel.fromJson(json['data']['default']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduleAsRunList': scheduleAsRunList.toJson(),
      'scheduleByDays': scheduleByDays.toJson(),
      'dayCountSchedule': dayCountSchedule.toJson(),
      'selected': selected,
    };
  }
}

class ScheduleAsRunListModel {
  Map<String, dynamic> rtc;
  Map<String, dynamic> schedule;

  ScheduleAsRunListModel({
    required this.rtc,
    required this.schedule,
  });

  factory ScheduleAsRunListModel.fromJson(Map<String, dynamic> json) {
    return ScheduleAsRunListModel(
      rtc: json['rtc'] ?? {
        "rtc1": {"onTime": "00:00:00", "offTime": "00:00:00", "interval": "00:00:00", "noOfCycles": "1", "maxTime": "00:00:00", "condition": false, "stopMethod": "Continuous"},
      },
      schedule: json['schedule'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rtc': rtc,
      'schedule': schedule,
    };
  }
}

class ScheduleByDaysModel {
  Map<String, dynamic> rtc;
  Map<String, dynamic> schedule;

  ScheduleByDaysModel({
    required this.rtc,
    required this.schedule,
  });

  factory ScheduleByDaysModel.fromJson(Map<String, dynamic> json) {
    return ScheduleByDaysModel(
      rtc: json['rtc'],
      schedule: json['schedule'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rtc': rtc,
      'schedule': schedule,
    };
  }
}

class DayCountSchedule {
  Map<String, dynamic> schedule;

  DayCountSchedule({
    required this.schedule,
  });

  factory DayCountSchedule.fromJson(Map<String, dynamic> json) {
    return DayCountSchedule(
      schedule: json['schedule'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule': schedule,
    };
  }
}

class DefaultModel {
  int runListLimit;
  bool rtcOffTime;
  bool rtcMaxTime;
  bool allowStopMethod;

  DefaultModel({
    required this.runListLimit,
    required this.rtcOffTime,
    required this.rtcMaxTime,
    required this.allowStopMethod
  });

  factory DefaultModel.fromJson(Map<String, dynamic> json) {
    return DefaultModel(
        runListLimit: json['runListLimit'],
        rtcOffTime: json['rtcOffTime'],
        rtcMaxTime: json['rtcMaxTime'],
        allowStopMethod: json['allowStopMethod'] ?? false
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'runListLimit': runListLimit,
      'rtcOffTime': rtcOffTime,
      'rtcMaxTime': rtcMaxTime,
      'allowStopMethod': allowStopMethod
    };
  }
}

class SampleConditions {
  List<Condition> condition;
  DefaultData defaultData;

  SampleConditions({required this.condition, required this.defaultData});

  factory SampleConditions.fromJson(Map<String, dynamic> json) {
    var conditionList = json['data']['condition'] as List;
    List<Condition> conditions =
    conditionList.map((e) => Condition.fromJson(e)).toList();

    return SampleConditions(
      condition: conditions,
      defaultData: DefaultData.fromJson(json['data']['default']),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return condition.map((e) => e.toJson()).toList();
  }
}

class Condition {
  int sNo;
  String title;
  int widgetTypeId;
  String iconCodePoint;
  String iconFontFamily;
  dynamic value;
  bool hidden;
  bool selected;

  Condition({
    required this.sNo,
    required this.title,
    required this.widgetTypeId,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.value,
    required this.hidden,
    required this.selected,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      sNo: json['sNo'],
      title: json['title'],
      widgetTypeId: json['widgetTypeId'],
      iconCodePoint: json['iconCodePoint'],
      iconFontFamily: json['iconFontFamily'],
      value: json['value'],
      hidden: json['hidden'],
      selected: json['selected'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sNo': sNo,
      'title': title,
      'value': value,
      'selected': selected,
    };
  }
}

class DefaultData {
  List<ConditionLibraryItem> conditionLibrary;

  DefaultData({required this.conditionLibrary});

  factory DefaultData.fromJson(Map<String, dynamic> json) {
    var conditionLibraryList = json['conditionLibrary'] as List;
    List<ConditionLibraryItem> conditionLibraryItems = conditionLibraryList
        .map((e) => ConditionLibraryItem.fromJson(e))
        .toList();

    return DefaultData(conditionLibrary: conditionLibraryItems);
  }
}

class ConditionLibraryItem {
  dynamic sNo;
  String name;
  bool status;
  String rule;
  String component;
  String threshold;
  String reason;
  String alertMessage;

  ConditionLibraryItem({
    required this.sNo,
    required this.name,
    required this.status,
    required this.rule,
    required this.component,
    required this.threshold,
    required this.reason,
    required this.alertMessage,
  });

  factory ConditionLibraryItem.fromJson(Map<String, dynamic> json) {
    // print("json in the sample conditions model :: $json");

    return ConditionLibraryItem(
      sNo: json['sNo'],
      name: json['name'],
      status: json['status'],
      rule: json['rule'],
      component: json['component'],
      threshold: json['threshold'],
      reason: json['reason'],
      alertMessage: json['alertMessage'],
    );
  }
}

class AdditionalData {
  String centralFiltrationOperationMode;
  String localFiltrationOperationMode;
  bool centralFiltrationBeginningOnly;
  bool localFiltrationBeginningOnly;
  bool pumpStationMode;
  bool changeOverMode;
  bool programBasedSet;
  bool programBasedInjector;
  List<dynamic> nodeSelection;

  AdditionalData(
      {required this.centralFiltrationOperationMode,
        required this.localFiltrationOperationMode,
        required this.centralFiltrationBeginningOnly,
        required this.localFiltrationBeginningOnly,
        required this.pumpStationMode,
        required this.changeOverMode,
        required this.programBasedSet,
        required this.programBasedInjector,
        required this.nodeSelection,
      });

  factory AdditionalData.fromJson(Map<String, dynamic> json) {
    return AdditionalData(
      centralFiltrationOperationMode: json['centralFiltrationOperationMode'] ?? "TIME",
      localFiltrationOperationMode: json['localFiltrationOperationMode'] ?? "TIME",
      centralFiltrationBeginningOnly: json['centralFiltrationBeginningOnly'] ?? false,
      localFiltrationBeginningOnly: json['localFiltrationBeginningOnly'] ?? false,
      pumpStationMode: json['pumpStationMode'] ?? false,
      changeOverMode: json['changeOverMode'] ?? false,
      programBasedSet: json['programBasedSet'] ?? false,
      programBasedInjector: json['programBasedInjector'] ?? false,
      nodeSelection: json['nodeSelection'] ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    "centralFiltrationOperationMode": centralFiltrationOperationMode,
    "localFiltrationOperationMode": localFiltrationOperationMode,
    "centralFiltrationBeginningOnly": centralFiltrationBeginningOnly,
    "localFiltrationBeginningOnly": localFiltrationBeginningOnly,
    "pumpStationMode": pumpStationMode,
    "changeOverMode": changeOverMode,
    "programBasedSet": programBasedSet,
    "programBasedInjector": programBasedInjector,
    "nodeSelection": nodeSelection,
  };
}

class AlarmData{
  final int sNo;
  final String name;
  final String unit;
  bool value;
  final bool hidden;
  final bool gemDisplay;
  final bool gemPayload;
  final bool ecoGemDisplay;
  final bool ecoGemPayload;

  AlarmData({
    required this.name,
    required this.unit,
    required this.value,
    required this.sNo,
    required this.hidden,
    required this.gemDisplay,
    required this.gemPayload,
    required this.ecoGemDisplay,
    required this.ecoGemPayload,
  });

  factory AlarmData.fromJson(Map<String, dynamic> json) {
    return AlarmData(
        name: json['title'],
        unit: json['unit'],
        value: json['value'] ?? false,
        sNo: json['sNo'],
        hidden: json['hidden'],
        gemDisplay: json['gemDisplay'],
        gemPayload: json['gemPayload'],
        ecoGemDisplay: json['ecoGemDisplay'],
        ecoGemPayload: json['ecoGemPayload']
    );
  }

  Map<String, dynamic> toJson(){
    return {
      "name": name,
      "unit": unit,
      "value": value,
      "sNo": sNo,
    };
  }
}

class NewAlarmList {
  List<AlarmData> alarmList;
  List<AlarmData> defaultAlarm;

  NewAlarmList({required this.alarmList, required this.defaultAlarm});

  factory NewAlarmList.fromJson(Map<String, dynamic> json) {
    List<dynamic> alarmJsonList = json['data']['alarm'];
    List<dynamic> defaultJsonList = json['data']['default']['globalAlarm'];
    List<AlarmData> alarmList = alarmJsonList
        .map((item) => AlarmData.fromJson(item))
        .toList();
    List<AlarmData> defaultAlarmList = defaultJsonList
        .map((item) => AlarmData.fromJson(item))
        .toList();

    return NewAlarmList(alarmList: alarmList, defaultAlarm: defaultAlarmList);
  }

  List<Map<String, dynamic>> toJson() {
    return alarmList.map((e) => e.toJson()).toList();
  }
}

class ProgramLibrary {
  List<String> defaultProgramTypes;
  List<Program> program;
  int programLimit;
  int agitatorCount;

  ProgramLibrary(
      {required this.defaultProgramTypes,
        required this.program,
        required this.programLimit,
        required this.agitatorCount});

  factory ProgramLibrary.fromJson(Map<String, dynamic> json) {
    List<String> programTypes = [json['data']['programType'][0] ?? 'Irrigation Program'];
    if(json['data']['agitatorCount'] > 0) {
      programTypes.add(json['data']['programType'][1]);
    }
    if(json['data']['fanCount'] > 0 || json['data']['foggerCount'] > 0 || json['data']['lightCount'] > 0) {
      programTypes.add(json['data']['programType'][2]);
    }
    print("json['data'] ==> ${json['data']}");
    if(json['data'].containsKey('aeratorCount')){
      if(json['data']['aeratorCount'] > 0) {
        programTypes.add(json['data']['programType'][3]);
      }
    }

    return ProgramLibrary(
      defaultProgramTypes: List<String>.from(programTypes),
      // programLimit: 4,
      programLimit: json['data']['programLimit'],
      agitatorCount: json['data']['agitatorCount'] ?? 0,
      program: List<Program>.from(
          (json['data']['program'] as List<dynamic>? ?? [])
              .map((program) => Program.fromJson(program))),
    );
  }
}

class Program {
  int programId;
  int serialNumber;
  String programName;
  String defaultProgramName;
  String programType;
  String priority;
  dynamic sequence;
  Map<String, dynamic> schedule;
  dynamic hardwareData;
  String controllerReadStatus;
  String active;

  Program(
      {required this.programId,
        required this.serialNumber,
        required this.programName,
        required this.defaultProgramName,
        required this.programType,
        required this.priority,
        required this.sequence,
        required this.schedule,
        required this.hardwareData,
        required this.controllerReadStatus,
        required this.active,
      });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      programId: json['programId'],
      serialNumber: json['serialNumber'],
      programName: json['programName'],
      defaultProgramName: json['defaultProgramName'],
      programType: json['programType'],
      priority: json['priority'],
      sequence: json['sequence'],
      schedule: json['schedule'],
      hardwareData: json['hardware'],
      controllerReadStatus: json['controllerReadStatus'],
      active: json['active'],
    );
  }
}

class ProgramDetails {
  // int programId;
  int serialNumber;
  String programName;
  String defaultProgramName;
  String programType;
  String priority;
  bool completionOption;
  String controllerReadStatus;
  String delayBetweenZones;
  String adjustPercentage;
  String cyclicOnTime;
  String cyclicOffTime;
  bool enablePressure;
  String pressureValue;
  String controlMode;
  String setPressure;
  String pressureTolerance;
  String setFlow;
  String flowTolerance;
  String flowScanTime;

  ProgramDetails(
      {
        // required this.programId,
        required this.serialNumber,
        required this.programName,
        required this.defaultProgramName,
        required this.programType,
        required this.priority,
        required this.completionOption,
        required this.delayBetweenZones,
        required this.controllerReadStatus,
        required this.adjustPercentage,
        required this.cyclicOnTime,
        required this.cyclicOffTime,
        required this.enablePressure,
        required this.pressureValue,
        required this.controlMode,
        required this.setPressure,
        required this.pressureTolerance,
        required this.setFlow,
        required this.flowTolerance,
        required this.flowScanTime,
      });

  factory ProgramDetails.fromJson(Map<String, dynamic> json) {
    return ProgramDetails(
      // programId: json['data']['programId'],
        serialNumber: json['data']['serialNumber'] ?? 0,
        programName: json['data']['programName'],
        defaultProgramName: json['data']['defaultProgramName'],
        programType: json['data']['programType'],
        priority: json['data']['priority'] == "" ? "Low" : json['data']['priority'],
        completionOption: json['data']['incompleteRestart'] == "1" ? true : false,
        delayBetweenZones: json["data"]["delayBetweenZones"],
        adjustPercentage: json["data"]["adjustPercentage"] == "0" ? "100" : json["data"]["adjustPercentage"],
        cyclicOnTime: json["data"]["cyclicOnTime"] ?? "00:00:00",
        cyclicOffTime: json["data"]["cyclicOffTime"] ?? "00:00:00",
        enablePressure: json["data"]["isPressureEnabled"] == '1' ? true : false,
        pressureValue: json["data"]["pressure"] ?? "0",
        controlMode: json["data"]["controlMode"] ?? "pressure",
        setPressure: json["data"]["setPressure"] ?? "0",
        pressureTolerance: json["data"]["pressureTolerance"] ?? "0",
        setFlow: json["data"]["setFlow"] ?? "0",
        flowTolerance: json["data"]["flowTolerance"] ?? "0",
        flowScanTime: json["data"]["flowScanTime"] ?? "00:00:00",
        controllerReadStatus: json['data']['controllerReadStatus'] ?? "0"
    );
  }
}

class ChartData {
  String sequenceName;
  String valves;
  int preValueLow;
  int preValueHigh;
  int postValueLow;
  int postValueHigh;
  dynamic constantSetting;
  dynamic waterValueLow;
  dynamic waterValueHigh;
  dynamic waterValueInTime;
  double flowRate;
  int method;

  ChartData({
    required this.sequenceName,
    required this.valves,
    required this.preValueLow,
    required this.preValueHigh,
    required this.postValueLow,
    required this.postValueHigh,
    required this.constantSetting,
    required this.waterValueLow,
    required this.waterValueHigh,
    required this.waterValueInTime,
    required this.flowRate,
    required this.method,
  });

  factory ChartData.fromJson(Map<String, dynamic> json, dynamic constantSetting, List<dynamic> valves) {
    int timeToSeconds(String time) {
      var splitTime = time.split(':');
      return int.parse(splitTime[0]) * 3600 + int.parse(splitTime[1]) * 60 + int.parse(splitTime[2]);
    }

    int calculateValueInSec(String value, List<dynamic> valves, dynamic constantSetting, String method) {
      if (method == 'Time') {
        int seconds = timeToSeconds(value);

        var nominalFlowRate = <String>[];
        var sno = <String>[];
        for (var val in valves) {
          for(var valveInConstant in constantSetting['valve']){
            if(!sno.contains(valveInConstant['sNo']) && valveInConstant['sNo'] == val['sNo']){
              sno.add(valveInConstant['sNo'].toString());
              var valveFlowRate = valveInConstant['setting'][0]['value'].toString();
              if(valveFlowRate.isNotEmpty){
                nominalFlowRate.add(valveFlowRate);
              }
            }
          }
        }
        var totalFlowRate = nominalFlowRate.map(int.parse).reduce((a, b) => a + b);
        var valveFlowRate = totalFlowRate * 0.00027778;

        // Calculate flow rate in liters
        // print(seconds);
        return seconds;
        var flowRateInTimePeriod = valveFlowRate * seconds;
        return flowRateInTimePeriod.round();
      } else {
        var nominalFlowRate = <String>[];
        var sno = <String>[];
        for (var val in valves) {
          for (var i = 0; i < constantSetting['valve'].length; i++) {
            for(var valveInConstant in constantSetting['valve']){
              if(!sno.contains(valveInConstant['sNo']) && valveInConstant['sNo'] == val['sNo']){
                sno.add(valveInConstant['sNo'].toString());
                var valveFlowRate = valveInConstant['setting'][0]['value'].toString();
                if(valveFlowRate.isNotEmpty){
                  nominalFlowRate.add(valveFlowRate);
                }
              }
            }
          }
        }
        var totalFlowRate = nominalFlowRate.map(int.parse).reduce((a, b) => a + b);
        var valveFlowRate = totalFlowRate * 0.00027778;
        return value == '0' ? 0 : (value.isNotEmpty ? int.parse(value) : 0);
      }
    }

    int preValue = calculateValueInSec(json['preValue'], valves, constantSetting,json['prePostMethod']);
    int postValue = calculateValueInSec(json['postValue'], valves, constantSetting,json['prePostMethod']);
    int preLow = 0;
    int preHigh = preValue;

    int waterLow = preHigh;
    int waterHigh = waterLow + (calculateValueInSec(json['method'] == 'Time' ? json['timeValue'] : json['quantityValue'], valves, constantSetting,json['method']) - preValue - postValue);
    int postLow = waterHigh;
    int postHigh = postLow + postValue;
    int waterValueInTime = postHigh;
    int method = json['method'] == 'Time' ? 1 : 0;

    double flowRate = calculateFlowRate(constantSetting, valves);

    return ChartData(
      sequenceName: json['seqName'] ?? "No name",
      valves: json['valve'].map((e) => e['name']).toList().join('\t\n'),
      preValueLow: preLow,
      preValueHigh: preHigh,
      constantSetting: constantSetting,
      waterValueLow: waterLow,
      waterValueHigh: waterHigh,
      postValueLow: postLow,
      postValueHigh: postHigh,
      waterValueInTime: waterValueInTime,
      flowRate: flowRate,
      method: method
    );
  }

  static double calculateFlowRate(dynamic constantSetting, List<dynamic> valves) {
    var nominalFlowRate = <String>[];
    var sno = <String>[];
    for (var val in valves) {
      for (var i = 0; i < constantSetting['valve'].length; i++) {
        for(var valveInConstant in constantSetting['valve']){
          if(!sno.contains(valveInConstant['sNo']) && valveInConstant['sNo'] == val['sNo']){
            sno.add(valveInConstant['sNo'].toString());
            var valveFlowRate = valveInConstant['setting'][0]['value'].toString();
            if(valveFlowRate.isNotEmpty){
              nominalFlowRate.add(valveFlowRate);
            }
          }
        }
      }
    }
    var totalFlowRate = nominalFlowRate.map(int.parse).reduce((a, b) => a + b);
    return totalFlowRate * 0.00027778;
  }
}

class DayCountRtcModel {
  bool dayCountRtc;
  String dayCountRtcTime;

  DayCountRtcModel({
    required this.dayCountRtc,
    required this.dayCountRtcTime,
  });

  factory DayCountRtcModel.fromJson(Map<String, dynamic> json) {
    return DayCountRtcModel(
        dayCountRtc: json["dayCountRtc"] ?? false,
        dayCountRtcTime: json["dayCountRtcTime"] ?? DateFormat('Hms').format(DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "dayCountRtc" : dayCountRtc,
      "dayCountRtcTime" : dayCountRtcTime
    };
  }
}


class ProgramQueueModel {
  bool programQueue;
  List<String> queueOrder;
  bool autoQueueRestart;
  List<String> queueOrderRestartTimes;
  bool skipDays;
  String noOfSkipDays;
  bool runDays;
  String noOfRunDays;
  bool queueReset;
  bool dripStandaloneMode;
  bool agitatorOnOff;
  String agitatorRTCOnTime;
  String agitatorRTCOffTime;
  String agitatorCycONTime;
  String agitatorCycOffTime;

  ProgramQueueModel({
    required this.programQueue,
    required this.queueOrder,
    required this.autoQueueRestart,
    required this.queueOrderRestartTimes,
    required this.skipDays,
    required this.noOfSkipDays,
    required this.runDays,
    required this.noOfRunDays,
    required this.queueReset,
    required this.dripStandaloneMode,
    required this.agitatorOnOff,
    required this.agitatorRTCOnTime,
    required this.agitatorRTCOffTime,
    required this.agitatorCycONTime,
    required this.agitatorCycOffTime,
  });

  // Helper method to safely convert a dynamic list to List<String>
  static List<String> _listToString(List<dynamic>? input, List<String> defaultValue) {
    if (input == null || input.isEmpty) {
      return defaultValue;
    }
    return input.map((e) => e.toString()).toList();
  }

  factory ProgramQueueModel.fromJson(Map<String, dynamic> json) {
    return ProgramQueueModel(
      programQueue: json["programQueue"] ?? false,
      queueOrder: _listToString(
        json["queueOrder"],
        ['0', '0', '0', '0'],
      ),
      autoQueueRestart: json["autoQueueRestart"] ?? false,
      queueOrderRestartTimes: _listToString(
        json["queueOrderRestartTimes"],
        ['00:03:00', '00:03:00', '00:03:00', '00:03:00'],
      ),
      skipDays: json["skipDays"] ?? false,
      noOfSkipDays: json["noOfSkipDays"] ?? '0',
      runDays: json["runDays"] ?? false,
      noOfRunDays: json["noOfRunDays"] ?? '0',
      queueReset: json["queueReset"] ?? false,
      dripStandaloneMode: json["dripStandaloneMode"] ?? false,
      agitatorOnOff: json["agitatorOnOff"] ?? false,
      agitatorRTCOnTime: json["agitatorRTCOnTime"] ?? "00:00:00",
      agitatorRTCOffTime: json["agitatorRTCOffTime"] ?? "00:00:00",
      agitatorCycONTime: json["agitatorCycONTime"] ?? "00:00:00",
      agitatorCycOffTime: json["agitatorCycOffTime"] ?? "00:00:00",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "programQueue": programQueue,
      "queueOrder": queueOrder,
      "autoQueueRestart": autoQueueRestart,
      "queueOrderRestartTimes": queueOrderRestartTimes,
      "skipDays": skipDays,
      "noOfSkipDays": noOfSkipDays,
      "runDays": runDays,
      "noOfRunDays": noOfRunDays,
      "queueReset": queueReset,
      "dripStandaloneMode": dripStandaloneMode,
      "agitatorOnOff" : agitatorOnOff,
      "agitatorRTCOnTime" : agitatorRTCOnTime,
      "agitatorRTCOffTime" : agitatorRTCOffTime,
      "agitatorCycONTime" : agitatorCycONTime,
      "agitatorCycOffTime" : agitatorCycOffTime,
    };
  }
}
