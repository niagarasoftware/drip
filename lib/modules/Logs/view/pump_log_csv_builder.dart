import 'pump_log_excel_builder.dart';

String generatePumpLogCsvString(PumpLogExportData exportData) {
  final sb = StringBuffer();

  String escapeCsv(String input) {
    final clean = input.replaceAll('"', '""');
    return '"$clean"';
  }

  // Section 1: Metadata
  sb.writeln('==========================================');
  sb.writeln('PUMP LOG REPORT');
  sb.writeln('Device Name,${escapeCsv(exportData.deviceName)}');
  sb.writeln('Device MAC,${escapeCsv(exportData.deviceId)}');
  sb.writeln('Date,${escapeCsv(exportData.dateStr)}');
  sb.writeln('Period,${escapeCsv(exportData.periodStr)}');
  sb.writeln('==========================================');
  sb.writeln();

  // Section 2: Pump Log
  sb.writeln('PUMP LOG');
  sb.writeln('Motor/Pump,On Time,Off Time,Duration,On Reason,Off Reason');

  final segments = exportData.segments.isNotEmpty
      ? exportData.segments
      : {0: 'Motor 1'};

  segments.forEach((key, motorName) {
    List events = [];
    if (key == 0) events = exportData.motor1Events;
    if (key == 1) events = exportData.motor2Events;
    if (key == 2) events = exportData.motor3Events;

    if (events.isEmpty) {
      sb.writeln('${escapeCsv(motorName)},-,-,-,"No events recorded",-');
    } else {
      for (final e in events) {
        sb.writeln(
          '${escapeCsv(motorName)},${escapeCsv(e.onTime)},${escapeCsv(e.offTime)},${escapeCsv(e.duration)},${escapeCsv(e.onReason)},${escapeCsv(e.offReason)}',
        );
      }
    }
  });

  sb.writeln();

  // Section 3: Voltage Log
  sb.writeln('VOLTAGE LOG');
  sb.writeln('Hour,Voltage R (V),Voltage Y (V),Voltage B (V),Current R (A),Current Y (A),Current B (A)');

  if (exportData.voltageData.isEmpty) {
    sb.writeln('-,-,-,-,-,-,-');
  } else {
    for (final row in exportData.voltageData) {
      sb.writeln(
        '${escapeCsv("${row['hour'] ?? '-'}")},${escapeCsv("${row['voltageR'] ?? '-'}")},${escapeCsv("${row['voltageY'] ?? '-'}")},${escapeCsv("${row['voltageB'] ?? '-'}")},${escapeCsv("${row['currentR'] ?? '-'}")},${escapeCsv("${row['currentY'] ?? '-'}")},${escapeCsv("${row['currentB'] ?? '-'}")}',
      );
    }
  }

  sb.writeln();

  // Section 4: Power Graph
  sb.writeln('POWER GRAPH');
  sb.writeln('Metric,Value,Unit');

  final motorData = exportData.motorData;
  sb.writeln('Total Power On Time,${escapeCsv(motorData?.totalPowerOnTime ?? "00:00:00")},HH:MM:SS');
  sb.writeln('Total Power Off Time,${escapeCsv(motorData?.totalPowerOffTime ?? "00:00:00")},HH:MM:SS');
  sb.writeln('Cumulative Flow,${escapeCsv(motorData?.overAllCumulativeFlow ?? "0")},Litres');
  sb.writeln('Pressure,${escapeCsv(motorData?.pressure ?? "0.0")},bar');
  sb.writeln('Flow Rate,${escapeCsv(motorData?.flowRate ?? "0.0")},Lps');
  sb.writeln('Level,${escapeCsv(motorData?.level ?? "0.0")},feet');

  segments.forEach((key, motorName) {
    String runTime = motorData?.motorRunTime1 ?? '00:00:00';
    String idleTime = motorData?.motorIdleTime1 ?? '00:00:00';
    String dryRun = motorData?.dryRunTripTime1 ?? '00:00:00';
    String cyclic = motorData?.cyclicTripTime1 ?? '00:00:00';
    String other = motorData?.otherTripTime1 ?? '00:00:00';
    String totalFlow = motorData?.totalFlowToday1 ?? '0';

    if (key == 1 && motorData != null) {
      runTime = motorData.motorRunTime2;
      idleTime = motorData.motorIdleTime2;
      dryRun = motorData.dryRunTripTime2;
      cyclic = motorData.cyclicTripTime2;
      other = motorData.otherTripTime2;
      totalFlow = motorData.totalFlowToday2;
    } else if (key == 2 && motorData != null) {
      runTime = motorData.motorRunTime3;
      idleTime = motorData.motorIdleTime3;
      dryRun = motorData.dryRunTripTime3;
      cyclic = motorData.cyclicTripTime3;
      other = motorData.otherTripTime3;
      totalFlow = motorData.totalFlowToday3;
    }

    sb.writeln('${escapeCsv("$motorName Run Time")},${escapeCsv(runTime)},HH:MM:SS');
    sb.writeln('${escapeCsv("$motorName Idle Time")},${escapeCsv(idleTime)},HH:MM:SS');
    sb.writeln('${escapeCsv("$motorName Dry Run Trip Time")},${escapeCsv(dryRun)},HH:MM:SS');
    sb.writeln('${escapeCsv("$motorName Cyclic Trip Time")},${escapeCsv(cyclic)},HH:MM:SS');
    sb.writeln('${escapeCsv("$motorName Other Trip Time")},${escapeCsv(other)},HH:MM:SS');
    sb.writeln('${escapeCsv("$motorName Total Flow")},${escapeCsv(totalFlow)},Litres');
  });

  return sb.toString();
}
