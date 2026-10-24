import 'package:excel/excel.dart';
import 'package:oro_drip_irrigation/modules/Logs/model/event_log_model.dart';
import 'package:oro_drip_irrigation/modules/Logs/model/motor_data_hourly.dart';

class PumpLogExportData {
  final String deviceName;
  final String deviceId;
  final String dateStr;
  final String periodStr;
  final Map<int, String> segments;
  final List<EventLog> motor1Events;
  final List<EventLog> motor2Events;
  final List<EventLog> motor3Events;
  final List<Map<String, dynamic>> voltageData;
  final MotorDataHourly? motorData;

  PumpLogExportData({
    required this.deviceName,
    required this.deviceId,
    required this.dateStr,
    required this.periodStr,
    required this.segments,
    required this.motor1Events,
    required this.motor2Events,
    required this.motor3Events,
    required this.voltageData,
    this.motorData,
  });
}

Excel buildPumpLogExcel(PumpLogExportData exportData) {
  final excel = Excel.createExcel();

  // ---------------------------------------------------------------------------
  // SHEET 1: Pump Log
  // ---------------------------------------------------------------------------
  final sheet1 = excel['Pump Log'];
  sheet1.appendRow([
    TextCellValue('Motor / Pump'),
    TextCellValue('On Time'),
    TextCellValue('Off Time'),
    TextCellValue('Duration'),
    TextCellValue('On Reason'),
    TextCellValue('Off Reason'),
  ]);

  final segments = exportData.segments.isNotEmpty
      ? exportData.segments
      : {0: 'Motor 1'};

  segments.forEach((key, motorName) {
    List<EventLog> events = [];
    if (key == 0) events = exportData.motor1Events;
    if (key == 1) events = exportData.motor2Events;
    if (key == 2) events = exportData.motor3Events;

    if (events.isEmpty) {
      sheet1.appendRow([
        TextCellValue(motorName),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('No events recorded'),
        TextCellValue('-'),
      ]);
    } else {
      for (final e in events) {
        sheet1.appendRow([
          TextCellValue(motorName),
          TextCellValue(e.onTime.isNotEmpty ? e.onTime : '-'),
          TextCellValue(e.offTime.isNotEmpty ? e.offTime : '-'),
          TextCellValue(e.duration.isNotEmpty ? e.duration : '-'),
          TextCellValue(e.onReason.isNotEmpty ? e.onReason : '-'),
          TextCellValue(e.offReason.isNotEmpty ? e.offReason : '-'),
        ]);
      }
    }
  });

  // ---------------------------------------------------------------------------
  // SHEET 2: Voltage Log
  // ---------------------------------------------------------------------------
  final sheet2 = excel['Voltage Log'];
  sheet2.appendRow([
    TextCellValue('Hour'),
    TextCellValue('Voltage R (V)'),
    TextCellValue('Voltage Y (V)'),
    TextCellValue('Voltage B (V)'),
    TextCellValue('Current R (A)'),
    TextCellValue('Current Y (A)'),
    TextCellValue('Current B (A)'),
  ]);

  if (exportData.voltageData.isEmpty) {
    sheet2.appendRow([
      TextCellValue('-'),
      TextCellValue('-'),
      TextCellValue('-'),
      TextCellValue('-'),
      TextCellValue('-'),
      TextCellValue('-'),
      TextCellValue('-'),
    ]);
  } else {
    for (final row in exportData.voltageData) {
      sheet2.appendRow([
        TextCellValue('${row['hour'] ?? '-'}'),
        TextCellValue('${row['voltageR'] ?? '-'}'),
        TextCellValue('${row['voltageY'] ?? '-'}'),
        TextCellValue('${row['voltageB'] ?? '-'}'),
        TextCellValue('${row['currentR'] ?? '-'}'),
        TextCellValue('${row['currentY'] ?? '-'}'),
        TextCellValue('${row['currentB'] ?? '-'}'),
      ]);
    }
  }

  // ---------------------------------------------------------------------------
  // SHEET 3: Power Graph
  // ---------------------------------------------------------------------------
  final sheet3 = excel['Power Graph'];
  sheet3.appendRow([
    TextCellValue('Metric'),
    TextCellValue('Value'),
    TextCellValue('Unit'),
  ]);

  final motorData = exportData.motorData;

  sheet3.appendRow([
    TextCellValue('Device Name'),
    TextCellValue(exportData.deviceName),
    TextCellValue(''),
  ]);
  if (exportData.deviceId.isNotEmpty) {
    sheet3.appendRow([
      TextCellValue('Device MAC'),
      TextCellValue(exportData.deviceId),
      TextCellValue(''),
    ]);
  }
  sheet3.appendRow([
    TextCellValue('Selected Date'),
    TextCellValue(exportData.dateStr),
    TextCellValue(''),
  ]);
  sheet3.appendRow([
    TextCellValue('Period'),
    TextCellValue(exportData.periodStr),
    TextCellValue(''),
  ]);
  sheet3.appendRow([
    TextCellValue('Total Power On Time'),
    TextCellValue(motorData?.totalPowerOnTime ?? '00:00:00'),
    TextCellValue('HH:MM:SS'),
  ]);
  sheet3.appendRow([
    TextCellValue('Total Power Off Time'),
    TextCellValue(motorData?.totalPowerOffTime ?? '00:00:00'),
    TextCellValue('HH:MM:SS'),
  ]);
  sheet3.appendRow([
    TextCellValue('Cumulative Flow'),
    TextCellValue(motorData?.overAllCumulativeFlow ?? '0'),
    TextCellValue('Litres'),
  ]);
  sheet3.appendRow([
    TextCellValue('Pressure'),
    TextCellValue(motorData?.pressure ?? '0.0'),
    TextCellValue('bar'),
  ]);
  sheet3.appendRow([
    TextCellValue('Flow Rate'),
    TextCellValue(motorData?.flowRate ?? '0.0'),
    TextCellValue('Lps'),
  ]);
  sheet3.appendRow([
    TextCellValue('Level'),
    TextCellValue(motorData?.level ?? '0.0'),
    TextCellValue('feet'),
  ]);

  segments.forEach((key, motorName) {
    String runTime = '00:00:00';
    String idleTime = '00:00:00';
    String dryRunTime = '00:00:00';
    String cyclicTime = '00:00:00';
    String otherTime = '00:00:00';
    String totalFlow = '0';

    if (motorData != null) {
      if (key == 1) {
        runTime = motorData.motorRunTime2;
        idleTime = motorData.motorIdleTime2;
        dryRunTime = motorData.dryRunTripTime2;
        cyclicTime = motorData.cyclicTripTime2;
        otherTime = motorData.otherTripTime2;
        totalFlow = motorData.totalFlowToday2;
      } else if (key == 2) {
        runTime = motorData.motorRunTime3;
        idleTime = motorData.motorIdleTime3;
        dryRunTime = motorData.dryRunTripTime3;
        cyclicTime = motorData.cyclicTripTime3;
        otherTime = motorData.otherTripTime3;
        totalFlow = motorData.totalFlowToday3;
      } else {
        runTime = motorData.motorRunTime1;
        idleTime = motorData.motorIdleTime1;
        dryRunTime = motorData.dryRunTripTime1;
        cyclicTime = motorData.cyclicTripTime1;
        otherTime = motorData.otherTripTime1;
        totalFlow = motorData.totalFlowToday1;
      }
    }

    sheet3.appendRow([
      TextCellValue('$motorName Run Time'),
      TextCellValue(runTime),
      TextCellValue('HH:MM:SS'),
    ]);
    sheet3.appendRow([
      TextCellValue('$motorName Idle Time'),
      TextCellValue(idleTime),
      TextCellValue('HH:MM:SS'),
    ]);
    sheet3.appendRow([
      TextCellValue('$motorName Dry Run Trip Time'),
      TextCellValue(dryRunTime),
      TextCellValue('HH:MM:SS'),
    ]);
    sheet3.appendRow([
      TextCellValue('$motorName Cyclic Trip Time'),
      TextCellValue(cyclicTime),
      TextCellValue('HH:MM:SS'),
    ]);
    sheet3.appendRow([
      TextCellValue('$motorName Other Trip Time'),
      TextCellValue(otherTime),
      TextCellValue('HH:MM:SS'),
    ]);
    sheet3.appendRow([
      TextCellValue('$motorName Total Flow'),
      TextCellValue(totalFlow),
      TextCellValue('Litres'),
    ]);
  });

  if (excel.sheets.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

  return excel;
}
