class MotorDataHourly {
  final String date;
  final int numberOfPumps;
  final String twoPhasePowerOnTime;
  final String overAllCumulativeFlow;
  final String flowRate;
  final String pressure;
  final String level;
  final String? totalInstantEnergy;
  final String? cumulativeEnergy;
  final String? powerFactorR;
  final String? powerFactorY;
  final String? powerFactorB;
  final String? powerR;
  final String? powerY;
  final String? powerB;
  final String twoPhaseLastPowerOnTime;
  final String threePhasePowerOnTime;
  final String threePhaseLastPowerOnTime;
  final String powerOffTime;
  final String lastPowerOnTime;
  final String totalPowerOnTime;
  final String totalPowerOffTime;
  final String motorRunTime1;
  final String motorIdleTime1;
  final String lastDateRunTime1;
  final String lastDateRunFlow1;
  final String dryRunTripTime1;
  final String cyclicTripTime1;
  final String otherTripTime1;
  final String totalFlowToday1;
  final String motorRunTime2;
  final String motorIdleTime2;
  final String lastDateRunTime2;
  final String lastDateRunFlow2;
  final String dryRunTripTime2;
  final String cyclicTripTime2;
  final String otherTripTime2;
  final String totalFlowToday2;
  final String motorRunTime3;
  final String motorIdleTime3;
  final String lastDateRunTime3;
  final String lastDateRunFlow3;
  final String dryRunTripTime3;
  final String cyclicTripTime3;
  final String otherTripTime3;
  final String totalFlowToday3;

  MotorDataHourly({
    required this.date,
    required this.overAllCumulativeFlow,
    required this.flowRate,
    required this.pressure,
    required this.level,
    required this.numberOfPumps,
    required this.totalInstantEnergy,
    required this.cumulativeEnergy,
    required this.powerFactorR,
    required this.powerFactorY,
    required this.powerFactorB,
    required this.powerR,
    required this.powerY,
    required this.powerB,
    required this.twoPhasePowerOnTime,
    required this.twoPhaseLastPowerOnTime,
    required this.threePhasePowerOnTime,
    required this.threePhaseLastPowerOnTime,
    required this.powerOffTime,
    required this.lastPowerOnTime,
    required this.totalPowerOnTime,
    required this.totalPowerOffTime,
    required this.motorRunTime1,
    required this.motorIdleTime1,
    required this.lastDateRunTime1,
    required this.lastDateRunFlow1,
    required this.dryRunTripTime1,
    required this.cyclicTripTime1,
    required this.otherTripTime1,
    required this.totalFlowToday1,
    required this.motorRunTime2,
    required this.motorIdleTime2,
    required this.lastDateRunTime2,
    required this.lastDateRunFlow2,
    required this.dryRunTripTime2,
    required this.cyclicTripTime2,
    required this.otherTripTime2,
    required this.totalFlowToday2,
    required this.motorRunTime3,
    required this.motorIdleTime3,
    required this.lastDateRunTime3,
    required this.lastDateRunFlow3,
    required this.dryRunTripTime3,
    required this.cyclicTripTime3,
    required this.otherTripTime3,
    required this.totalFlowToday3,
  });
  factory MotorDataHourly.fromJson(Map<String, dynamic> json) {
    String getCumulativeFlow(Map<String, dynamic> json, String key) {
      final raw = json[key]?.toString().trim() ?? "";
      if (raw.isEmpty || raw == "-" || raw == "null") {
        return "0";
      }
      int firstIndex = -1;
      for (int i = 0; i < raw.length; i++) {
        final code = raw.codeUnitAt(i);
        if (code >= 49 && code <= 57) { // '1' - '9'
          firstIndex = i;
          break;
        }
      }
      if (firstIndex == -1) {
        return "0";
      }
      return raw.substring(firstIndex);
    }

    final int numPumps = json['numberOfPumps'] is int
        ? (json['numberOfPumps'] > 3 ? 3 : json['numberOfPumps'])
        : (int.tryParse(json['numberOfPumps']?.toString() ?? '1') ?? 1);

    return MotorDataHourly(
      date: json['date']?.toString() ?? "",
      numberOfPumps: numPumps > 3 ? 3 : (numPumps < 1 ? 1 : numPumps),
      twoPhasePowerOnTime: json['twoPhasePowerOnTime']?.toString() ?? "00:00:00",
      twoPhaseLastPowerOnTime: json['twoPhaseLastPowerOnTime']?.toString() ?? "00:00:00",
      threePhasePowerOnTime: json['threePhasePowerOnTime']?.toString() ?? "00:00:00",
      overAllCumulativeFlow: getCumulativeFlow(json, 'overAllCumulativeFlow'),
      flowRate: json['flowRate']?.toString() ?? "0.0",
      pressure: json['pressure']?.toString() ?? "0.0",
      level: json['level']?.toString() ?? "0.0",
      totalInstantEnergy: json['totalInstantEnergy']?.toString(),
      cumulativeEnergy: json['cumulativeEnergy']?.toString(),
      powerFactorR: json['powerFactorR']?.toString(),
      powerFactorY: json['powerFactorY']?.toString(),
      powerFactorB: json['powerFactorB']?.toString(),
      powerR: json['powerR']?.toString(),
      powerY: json['powerY']?.toString(),
      powerB: json['powerB']?.toString(),
      threePhaseLastPowerOnTime: json['threePhaseLastPowerOnTime']?.toString() ?? "00:00:00",
      powerOffTime: json['powerOffTime']?.toString() ?? "00:00:00",
      lastPowerOnTime: json['lastPowerOnTime']?.toString() ?? "00:00:00",
      totalPowerOnTime: json['totalPowerOnTime']?.toString() ?? "00:00:00",
      totalPowerOffTime: json['totalPowerOffTime']?.toString() ?? "00:00:00",
      motorRunTime1: json['motorRunTime1']?.toString() ?? "00:00:00",
      motorIdleTime1: json['motorIdleTime1']?.toString() ?? "00:00:00",
      lastDateRunTime1: json['lastDateRunTime1']?.toString() ?? "00:00:00",
      lastDateRunFlow1: json['lastDateRunFlow1']?.toString() ?? "0",
      dryRunTripTime1: json['dryRunTripTime1']?.toString() ?? "00:00:00",
      cyclicTripTime1: json['cyclicTripTime1']?.toString() ?? "00:00:00",
      otherTripTime1: json['otherTripTime1']?.toString() ?? "00:00:00",
      totalFlowToday1: getCumulativeFlow(json, 'totalFlowToday1'),
      motorRunTime2: json['motorRunTime2']?.toString() ?? "00:00:00",
      motorIdleTime2: json['motorIdleTime2']?.toString() ?? "00:00:00",
      lastDateRunTime2: json['lastDateRunTime2']?.toString() ?? "00:00:00",
      lastDateRunFlow2: json['lastDateRunFlow2']?.toString() ?? "0",
      dryRunTripTime2: json['dryRunTripTime2']?.toString() ?? "00:00:00",
      cyclicTripTime2: json['cyclicTripTime2']?.toString() ?? "00:00:00",
      otherTripTime2: json['otherTripTime2']?.toString() ?? "00:00:00",
      totalFlowToday2: getCumulativeFlow(json, 'totalFlowToday2'),
      motorRunTime3: json['motorRunTime3']?.toString() ?? "00:00:00",
      motorIdleTime3: json['motorIdleTime3']?.toString() ?? "00:00:00",
      lastDateRunTime3: json['lastDateRunTime3']?.toString() ?? "00:00:00",
      lastDateRunFlow3: json['lastDateRunFlow3']?.toString() ?? "0",
      dryRunTripTime3: json['dryRunTripTime3']?.toString() ?? "00:00:00",
      cyclicTripTime3: json['cyclicTripTime3']?.toString() ?? "00:00:00",
      otherTripTime3: json['otherTripTime3']?.toString() ?? "00:00:00",
      totalFlowToday3: getCumulativeFlow(json, 'totalFlowToday3'),
    );
  }
}