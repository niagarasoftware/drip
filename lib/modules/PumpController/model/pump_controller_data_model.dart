class PumpControllerData {
  List<IndividualPumpData> pumps;
  dynamic voltage;
  dynamic current;
  dynamic signalStrength;
  dynamic batteryStrength;
  dynamic version;
  dynamic energyParameters;
  dynamic powerFactor;
  dynamic power;
  String numberOfPumps;
  int dataFetchingStatus;
  String manualMode;
  String changeOverMode;

  PumpControllerData({
    required this.pumps,
    required this.voltage,
    required this.current,
    required this.batteryStrength,
    required this.signalStrength,
    required this.numberOfPumps,
    required this.version,
    required this.energyParameters,
    required this.powerFactor,
    required this.power,
    required this.dataFetchingStatus,
    this.manualMode = '0',
    this.changeOverMode = '0',
  });

  factory PumpControllerData.fromJson(Map<String, dynamic> json, String key, int dataFetchingStatus) {
    print("json in the PumpControllerData :: $json");
    List<dynamic> pumpsJson = json[key] ?? [];
    dynamic lastElement = {};

    if (pumpsJson.isNotEmpty) {
      lastElement = pumpsJson.last;
      pumpsJson.removeLast();
    }

    List<IndividualPumpData> pumps = [];

    if (pumpsJson.isNotEmpty) {
      pumps.add(IndividualPumpData.fromJson(pumpsJson[0]));
      pumps.addAll(
        pumpsJson.skip(1).whereType<Map<String, dynamic>>().map((x) => x.containsKey("VOM")
            ? PumpValveModel.fromJson(x)
            : IndividualPumpData.fromJson(x)).cast<IndividualPumpData>(),
      );
    }

    return PumpControllerData(
      pumps: pumps,
      voltage: lastElement['V'] ?? "",
      current: lastElement['C'] ?? "",
      version: lastElement['VS'],
      powerFactor: lastElement['PF'],
      power: lastElement['P'],
      energyParameters: lastElement['E'] ?? "",
      signalStrength: lastElement['SS'] ?? "",
      batteryStrength: lastElement['B'] ?? "",
      numberOfPumps: lastElement['NP'] ?? "0",
      dataFetchingStatus: dataFetchingStatus,
      manualMode: lastElement['MM'] ?? '0',
      changeOverMode: lastElement['COM'] ?? '0'
    );
  }
}

class IndividualPumpData {
  int status;
  String reason;
  int reasonCode;
  String waterMeter;
  String cumulativeFlow;
  dynamic pressure;
  dynamic actual;
  dynamic set;
  String level;
  dynamic phase;
  String float;
  String onDelayTimer;
  String onDelayComplete;
  String onDelayLeft;
  String cyclicOffDelay;
  String cyclicOnDelay;
  String maximumRunTimeRemaining;
  String dryRunRestartTimeRemaining;

  IndividualPumpData({
    required this.status,
    required this.reason,
    required this.reasonCode,
    required this.waterMeter,
    required this.cumulativeFlow,
    required this.pressure,
    required this.actual,
    required this.set,
    required this.level,
    required this.phase,
    required this.float,
    required this.onDelayTimer,
    required this.onDelayComplete,
    required this.onDelayLeft,
    required this.cyclicOffDelay,
    required this.cyclicOnDelay,
    required this.maximumRunTimeRemaining,
    required this.dryRunRestartTimeRemaining,
  });

  factory IndividualPumpData.fromJson(Map<String, dynamic> json) {
    final value = json["CF"] ?? "-";
    int firstIndex = 0;
    if (value != "-") {
      for (int i = 0; i < value.length; i++) {
        if (int.tryParse(value[i]) != null && int.parse(value[i]) > 0) {
          firstIndex = i;
          break;
        }
      }
    }

    final reason = json["RN"];
    final status = json["ST"];
    const String motorOff = "Motor off due to";
    const String motorOn = "Motor on due to";

    return IndividualPumpData(
      reasonCode: reason ?? 0,
      status: status ?? 0,
      reason: reason == 1 ? "$motorOff sump empty"
          : reason == 2 ? "$motorOff upper tank full"
          : reason == 3 ? "$motorOff low voltage"
          : reason == 4 ? "$motorOff high voltage"
          : reason == 5 ? "$motorOff voltage SPP"
          : reason == 6 ? "$motorOff reverse phase"
          : reason == 7 ? "$motorOff starter trip"
          : reason == 8 ? "$motorOff dry run"
          : reason == 9 ? "$motorOff overload"
          : reason == 10 ? "$motorOff current SPP"
          : reason == 11 ? "$motorOff cyclic trip"
          : reason == 12 ? "$motorOff maximum run time"
          : reason == 13 ? "$motorOff sump empty"
          : reason == 14 ? "$motorOff upper tank full"
          : reason == 15 ? "$motorOff RTC 1"
          : reason == 16 ? "$motorOff RTC 2"
          : reason == 17 ? "$motorOff RTC 3"
          : reason == 18 ? "$motorOff RTC 4"
          : reason == 19 ? "$motorOff RTC 5"
          : reason == 20 ? "$motorOff RTC 6"
          : reason == 21 ? "$motorOff auto mobile key off"
          : reason == 22 ? "$motorOn cyclic time"
          : reason == 23 ? "$motorOn RTC 1"
          : reason == 24 ? "$motorOn RTC 2"
          : reason == 25 ? "$motorOn RTC 3"
          : reason == 26 ? "$motorOn RTC 4"
          : reason == 27 ? "$motorOn RTC 5"
          : reason == 28 ? "$motorOn RTC 6"
          : reason == 29 ? "$motorOn auto mobile key on"
          : reason == 30 ? "Power off"
          : reason == 31 ? "Power on"
          : reason == 32 ? "Ready to start"
          : reason == 33 ? "$motorOff 3 Phase only"
          : reason == 35 ? "$motorOff Cyclic interval"
          : reason == 36 ? "$motorOff Moisture limit"
          : reason == 37 ? "$motorOff Cycles completed"
          : reason == 38 ? "$motorOff Cycle pause"
          : reason == 39 ? "$motorOff wrong feedback"
          : reason == 40 ? "No communication"
          : reason == 41 ? "$motorOff Pressure sensor low"
          : reason == 42 ? "$motorOff Pressure sensor high"
          : reason == 43 ? "$motorOff sump cable disconnected"
          : reason == 44 ? "$motorOff tank cable disconnected"
          : reason == 45 ? "$motorOff sump float failed"
          : reason == 46 ? "$motorOff tank float failed"
          : reason == 47 ? "$motorOn Auto On Power On"
          : reason == 48 ? "$motorOff Auto Off Power On"
          : "Unknown",
      waterMeter: json["WM"] ?? "",
      cumulativeFlow: value != "-" ? value.substring(firstIndex) : "-",
      phase: json['PH'],
      pressure: json["PR"],
      actual: json["AT"],
      set: json["SE"],
      level: json["LV"] ?? "",
      float: json["FT"] ?? "",
      onDelayTimer: json["OD"] ?? "",
      onDelayComplete: json["ODC"] ?? "",
      onDelayLeft: json["ODL"] ?? "",
      cyclicOffDelay: json["CFDL"] ?? "",
      cyclicOnDelay: json["CNDL"] ?? "",
      maximumRunTimeRemaining: json["MR"] ?? "",
      dryRunRestartTimeRemaining: json["DRST"] ?? "",
    );
  }
}

class ValveData {
  final String duration;
  String status;

  ValveData({required this.duration, required this.status});

  factory ValveData.fromRaw(String raw) {
    final parts = raw.split(',');
    final duration = parts[0];
    final status = parts[1];
    return ValveData(duration: duration, status: status);
  }

  Map<String, dynamic> toJson() {
    final timeParts = duration.split(':');
    return {
      'raw': '${timeParts[0]},${timeParts[1]},$status',
    };
  }
}

class PumpValveModel extends IndividualPumpData {
  final String valveOnMode;
  final Map<String, ValveData> valves;
  final String remainingTime;
  final String cyclicRestartFlag;
  final String cyclicRestartInterval;
  final String cyclicRestartIntervalRem;
  final String cyclicRestartLimit;
  final String currentCycle;
  final String cycleCompletedFlag;
  String setSerialFlag;
  final String moistureValues;
  final String soilTemperature;
  final String phaseType;
  final String lightReason;
  String? light;

  PumpValveModel({
    required this.valveOnMode,
    required this.valves,
    required this.remainingTime,
    required this.cyclicRestartFlag,
    required this.cyclicRestartInterval,
    required this.cyclicRestartIntervalRem,
    required this.cyclicRestartLimit,
    required this.currentCycle,
    required this.cycleCompletedFlag,
    required this.setSerialFlag,
    required this.moistureValues,
    required this.soilTemperature,
    required this.phaseType,
    required this.lightReason,
    required this.light,
  }) : super(
    status: 0,
    reason: '',
    reasonCode: 0,
    waterMeter: '',
    cumulativeFlow: '',
    pressure: '',
    actual: '',
    set: '',
    level: '',
    phase: '',
    float: '',
    onDelayTimer: '',
    onDelayComplete: '',
    onDelayLeft: '',
    cyclicOffDelay: '',
    cyclicOnDelay: '',
    maximumRunTimeRemaining: '',
    dryRunRestartTimeRemaining: '',
  );

  factory PumpValveModel.fromJson(Map<String, dynamic> json) {
    final Map<String, ValveData> valveMap = {};
    for (int i = 1; i <= 10; i++) {
      final key = 'V$i';
      if (json[key] != null) {
        valveMap[key] = ValveData.fromRaw(json[key]);
      }
    }

    return PumpValveModel(
      valveOnMode: json['VOM'] ?? '',
      valves: valveMap,
      remainingTime: json['RT'] ?? '',
      cyclicRestartFlag: json['CRSF'] ?? '',
      cyclicRestartInterval: json['CRST'] ?? '',
      cyclicRestartIntervalRem: json['CRM'] ?? '',
      cyclicRestartLimit: json['CRSL'] ?? '',
      currentCycle: json['CNO'] ?? '',
      cycleCompletedFlag: json['CCF'] ?? '',
      setSerialFlag: json['SS'] ?? '',
      moistureValues: json['MOS'] ?? '',
      soilTemperature: json['STM'] ?? '',
      phaseType: json['SPF'] ?? '',
      lightReason: getReason(json['LIS'] ?? '').toUpperCase(),
      light: json['LIT'] ?? '',
    );
  }

  static String getReason(String reasonCode) {
    switch(reasonCode) {
      case "1":
        return "Turned on due to stanalone";
      case "2":
        return "Turned on due to RTC";
      case "3":
        return "Turned off due to stanalone";
      case "4":
        return "Turned off due to RTC";
      default:
        return "";
    }
  }

  Map<String, dynamic> toJson() {
    final data = {
      'VOM': valveOnMode,
      'RT': remainingTime,
      'CRSF': cyclicRestartFlag,
      'CRST': cyclicRestartInterval,
      'CRSL': cyclicRestartLimit,
    };
    valves.forEach((key, value) {
      data[key] = '${value.duration.split(':')[0]},${value.duration.split(':')[1]},${value.status}';
    });
    return data;
  }
}
