import 'dart:convert';
import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'zone_log_pdf_builder.dart';

Future<String?> exportZoneLogToCSV(
    List<dynamic> records, String fileName) async {
  try {
    StringBuffer sb = StringBuffer();
    sb.writeln(
        'Date,Program Name,Sequence Name,HeadUnit,Pump,Start Time,End Time,Duration,Start Reason,End Reason');

    for (var rec in records) {
      String dateStr = rec.dateStr.replaceAll('"', '""');
      String progStr = rec.programTitle.replaceAll('"', '""');
      String seqStr = rec.sequenceTitle.replaceAll('"', '""');
      String huStr = rec.headUnit.replaceAll('"', '""');
      String pumpStr = rec.pump.replaceAll('"', '""');
      String startStr = rec.startTime.replaceAll('"', '""');
      String endStr = rec.endTime.replaceAll('"', '""');
      String durStr = rec.duration.replaceAll('"', '""');
      String startRStr = rec.startReason.replaceAll('"', '""');
      String endRStr = rec.endReason.replaceAll('"', '""');

      sb.writeln(
          '"$dateStr","$progStr","$seqStr","$huStr","$pumpStr","$startStr","$endStr","$durStr","$startRStr","$endRStr"');
    }

    final bytes = utf8.encode(sb.toString());
    final content = base64Encode(bytes);
    html.AnchorElement(
      href: 'data:text/csv;charset=utf-8;base64,$content',
    )
      ..setAttribute('download', '$fileName.csv')
      ..click();

    return "Downloaded $fileName.csv";
  } catch (e) {
    debugPrint("Error exporting CSV Web: $e");
    return null;
  }
}

Future<String?> exportZoneLogToPDF(
    List<dynamic> records, String fileName) async {
  try {
    final pdfBytes = generateZoneLogPdfBytes(records, fileName);
    final content = base64Encode(pdfBytes);
    html.AnchorElement(
      href: 'data:application/pdf;base64,$content',
    )
      ..setAttribute('download', '$fileName.pdf')
      ..click();

    return "Downloaded $fileName.pdf";
  } catch (e) {
    debugPrint("Error exporting PDF Web: $e");
    return null;
  }
}

Future<String?> exportZoneLogMatrixToExcel({
  required List<DateTime> dateColumns,
  required List<dynamic> rows,
  required Map<String, int> dailyTotals,
  Map<String, num>? dailyTotalQuantities,
  required int grandTotalSeconds,
  num grandTotalQuantity = 0,
  required String fileName,
}) async {
  try {
    final excel = Excel.createExcel();
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final Sheet sheet = excel[defaultSheet];

    List<CellValue> header1 = [TextCellValue('')];
    for (var d in dateColumns) {
      String dateStr = DateFormat('dd/MM/yyyy (E)').format(d);
      header1.add(TextCellValue(dateStr));
    }
    header1.add(TextCellValue('Total'));
    sheet.appendRow(header1);

    List<CellValue> header2 = [TextCellValue('Program / Valve / Sequence')];
    for (var _ in dateColumns) {
      header2.add(TextCellValue('Duration / Quantity'));
    }
    header2.add(TextCellValue('Total Duration / Quantity'));
    sheet.appendRow(header2);

    for (var row in rows) {
      List<CellValue> dataRow = [];
      String displayName = row.seqName;
      String vName = (row.valveName ?? '').toString();
      if (vName.isNotEmpty) {
        displayName = (row.progName.isNotEmpty && row.progName != row.seqName)
            ? "${row.progName} - $vName - ${row.seqName}"
            : "$vName - ${row.seqName}";
      } else if (row.progName.isNotEmpty && row.progName != row.seqName) {
        displayName = "${row.progName} - ${row.seqName}";
      }
      dataRow.add(TextCellValue(displayName));

      int rowTotalSec = 0;
      num rowTotalQty = 0;
      for (var d in dateColumns) {
        String dKey = DateFormat('yyyy-MM-dd').format(d);
        var dayData = row.dayEntries[dKey];
        if (dayData != null && dayData.hasRun) {
          int sec = (dayData.durationQtySeconds as int? ?? 0);
          num qtyVal = (dayData.quantityCompleted as num? ?? dayData.quantity as num? ?? 0);
          String qtyStr = qtyVal > 0
              ? (qtyVal % 1 == 0 ? "${qtyVal.toInt()} L" : "$qtyVal L")
              : '-';
          dataRow.add(TextCellValue("${dayData.durationQtyStr} / $qtyStr"));
          rowTotalSec += sec;
          rowTotalQty += qtyVal;
        } else {
          dataRow.add(TextCellValue('- / -'));
        }
      }
      String totalDur = _formatDurationHelper(rowTotalSec);
      String totalQty = rowTotalQty > 0
          ? (rowTotalQty % 1 == 0 ? "${rowTotalQty.toInt()} L" : "$rowTotalQty L")
          : '-';
      dataRow.add(TextCellValue("$totalDur / $totalQty"));
      sheet.appendRow(dataRow);
    }

    List<CellValue> footerRow = [TextCellValue('Total')];
    for (var d in dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySec = dailyTotals[dKey] ?? 0;
      num dayQty = dailyTotalQuantities?[dKey] ?? 0;
      String dayDur = _formatDurationHelper(daySec);
      String dayQtyStr = dayQty > 0
          ? (dayQty % 1 == 0 ? "${dayQty.toInt()} L" : "$dayQty L")
          : '-';
      footerRow.add(TextCellValue("$dayDur / $dayQtyStr"));
    }
    String gDur = _formatDurationHelper(grandTotalSeconds);
    String gQty = grandTotalQuantity > 0
        ? (grandTotalQuantity % 1 == 0
            ? "${grandTotalQuantity.toInt()} L"
            : "$grandTotalQuantity L")
        : '-';
    footerRow.add(TextCellValue("$gDur / $gQty"));
    sheet.appendRow(footerRow);

    final fileBytes = excel.encode();
    if (fileBytes == null) return null;

    final content = base64Encode(fileBytes);
    html.AnchorElement(
      href:
          'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$content',
    )
      ..setAttribute('download', '$fileName.xlsx')
      ..click();

    return "$fileName.xlsx";
  } catch (e) {
    debugPrint("Error exporting Zone Log matrix to Excel Web: $e");
    return null;
  }
}

Future<String?> exportZoneLogMatrixToPdf({
  required List<DateTime> dateColumns,
  required List<dynamic> rows,
  required Map<String, int> dailyTotals,
  Map<String, num>? dailyTotalQuantities,
  required int grandTotalSeconds,
  num grandTotalQuantity = 0,
  required String fileName,
}) async {
  try {
    final pdfBytes = generateZoneLogMatrixPdfBytes(
      dateColumns: dateColumns,
      rows: rows,
      dailyTotals: dailyTotals,
      dailyTotalQuantities: dailyTotalQuantities,
      grandTotalSeconds: grandTotalSeconds,
      grandTotalQuantity: grandTotalQuantity,
      fileName: fileName,
    );

    final content = base64Encode(pdfBytes);
    html.AnchorElement(
      href: 'data:application/pdf;base64,$content',
    )
      ..setAttribute('download', '$fileName.pdf')
      ..click();

    return "$fileName.pdf";
  } catch (e) {
    debugPrint("Error exporting Zone Log matrix PDF Web: $e");
    return null;
  }
}

String _formatDurationHelper(int totalSeconds) {
  if (totalSeconds <= 0) return "0h 0m";
  int hours = totalSeconds ~/ 3600;
  int minutes = (totalSeconds % 3600) ~/ 60;
  int seconds = totalSeconds % 60;
  if (seconds > 0) {
    return "${hours}h ${minutes}m ${seconds}s";
  }
  return "${hours}h ${minutes}m";
}

String _formatSecondsToHMS(int totalSecs) {
  int h = totalSecs ~/ 3600;
  int m = (totalSecs % 3600) ~/ 60;
  int s = totalSecs % 60;
  return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
}

Future<String?> exportPumpLogMatrixToExcel({
  required List<DateTime> dateColumns,
  required List<dynamic> rows,
  required Map<String, int> dailyRunTotals,
  required Map<String, int> dailyPowerOnTotals,
  required Map<String, int> dailyPowerOffTotals,
  required int grandTotalRunSeconds,
  required int grandTotalPowerOnSeconds,
  required int grandTotalPowerOffSeconds,
  required String fileName,
}) async {
  try {
    final excel = Excel.createExcel();
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final Sheet sheet = excel[defaultSheet];

    List<CellValue> header1 = [TextCellValue('Pump Details')];
    for (var d in dateColumns) {
      String dateStr = DateFormat('dd/MM/yyyy (E)').format(d);
      header1.add(TextCellValue(dateStr));
    }
    header1.add(TextCellValue('Total'));
    sheet.appendRow(header1);

    List<CellValue> header2 = [TextCellValue('Pump')];
    for (var _ in dateColumns) {
      header2.add(
          TextCellValue("Runtime /\nTotal Power On /\nTotal Power Off Time"));
    }
    header2.add(
        TextCellValue("Runtime /\nTotal Power On /\nTotal Power Off Time"));
    sheet.appendRow(header2);

    for (var row in rows) {
      List<CellValue> dataRow = [];
      String cat = row.channelCategory?.toString() ?? '';
      String name = row.channelName?.toString() ?? '';
      String displayName = (cat.isNotEmpty && name.isNotEmpty)
          ? "$cat\n$name"
          : (name.isNotEmpty ? name : (cat.isNotEmpty ? cat : "Pump"));
      dataRow.add(TextCellValue(displayName));

      for (var d in dateColumns) {
        String dKey = DateFormat('yyyy-MM-dd').format(d);
        var dayData = row.dayEntries[dKey];
        int sec = dayData?.durationSeconds ?? 0;
        int onSec = dayData?.powerOnSeconds ?? 0;
        int offSec = dayData?.powerOffSeconds ?? 0;
        bool hasAct = sec > 0 || onSec > 0 || offSec > 0;
        bool hasRun = dayData != null && dayData.hasRun;

        if (hasAct || hasRun) {
          String rStr =
              sec > 0 ? "${_formatSecondsToHMS(sec)} /" : "00:00:00 /";
          String onStr =
              onSec > 0 ? "${_formatSecondsToHMS(onSec)} /" : "00:00:00 /";
          String offStr =
              offSec > 0 ? _formatSecondsToHMS(offSec) : "00:00:00";
          dataRow.add(TextCellValue("$rStr\n$onStr\n$offStr"));
        } else {
          dataRow.add(TextCellValue("- /\n- /\n-"));
        }
      }

      int totSec = row.totalDurationSeconds ?? 0;
      int totOn = row.totalPowerOnSeconds ?? 0;
      int totOff = row.totalPowerOffSeconds ?? 0;
      String rRun =
          totSec > 0 ? "${_formatDurationHelper(totSec)} /" : "- /";
      String rOn =
          totOn > 0 ? "${_formatDurationHelper(totOn)} /" : "- /";
      String rOff = totOff > 0 ? _formatDurationHelper(totOff) : "-";
      dataRow.add(TextCellValue("$rRun\n$rOn\n$rOff"));
      sheet.appendRow(dataRow);
    }

    List<CellValue> footerRow = [TextCellValue('Total')];
    for (var d in dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int dayRun = dailyRunTotals[dKey] ?? 0;
      int dayOn = dailyPowerOnTotals[dKey] ?? 0;
      int dayOff = dailyPowerOffTotals[dKey] ?? 0;
      bool hasAct = dayRun > 0 || dayOn > 0 || dayOff > 0;

      String dRun = dayRun > 0
          ? "${_formatDurationHelper(dayRun)} /"
          : (hasAct ? "0h 0m /" : "- /");
      String dOn = dayOn > 0
          ? "${_formatDurationHelper(dayOn)} /"
          : (hasAct ? "0h 0m /" : "- /");
      String dOff = dayOff > 0
          ? _formatDurationHelper(dayOff)
          : (hasAct ? "0h 0m" : "-");
      footerRow.add(TextCellValue("$dRun\n$dOn\n$dOff"));
    }

    bool hasGAct = grandTotalRunSeconds > 0 ||
        grandTotalPowerOnSeconds > 0 ||
        grandTotalPowerOffSeconds > 0;
    String gRun = grandTotalRunSeconds > 0
        ? "${_formatDurationHelper(grandTotalRunSeconds)} /"
        : (hasGAct ? "0h 0m /" : "- /");
    String gOn = grandTotalPowerOnSeconds > 0
        ? "${_formatDurationHelper(grandTotalPowerOnSeconds)} /"
        : (hasGAct ? "0h 0m /" : "- /");
    String gOff = grandTotalPowerOffSeconds > 0
        ? _formatDurationHelper(grandTotalPowerOffSeconds)
        : (hasGAct ? "0h 0m" : "-");
    footerRow.add(TextCellValue("$gRun\n$gOn\n$gOff"));
    sheet.appendRow(footerRow);

    final fileBytes = excel.encode();
    if (fileBytes == null) return null;

    final content = base64Encode(fileBytes);
    html.AnchorElement(
      href:
          'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$content',
    )
      ..setAttribute('download', '$fileName.xlsx')
      ..click();

    return "$fileName.xlsx";
  } catch (e) {
    debugPrint("Error exporting Pump Log matrix to Excel Web: $e");
    return null;
  }
}

Future<String?> exportPumpLogMatrixToPdf({
  required List<DateTime> dateColumns,
  required List<dynamic> rows,
  required Map<String, int> dailyRunTotals,
  required Map<String, int> dailyPowerOnTotals,
  required Map<String, int> dailyPowerOffTotals,
  required int grandTotalRunSeconds,
  required int grandTotalPowerOnSeconds,
  required int grandTotalPowerOffSeconds,
  required String fileName,
}) async {
  try {
    final pdfBytes = generatePumpLogMatrixPdfBytes(
      dateColumns: dateColumns,
      rows: rows,
      dailyRunTotals: dailyRunTotals,
      dailyPowerOnTotals: dailyPowerOnTotals,
      dailyPowerOffTotals: dailyPowerOffTotals,
      grandTotalRunSeconds: grandTotalRunSeconds,
      grandTotalPowerOnSeconds: grandTotalPowerOnSeconds,
      grandTotalPowerOffSeconds: grandTotalPowerOffSeconds,
      fileName: fileName,
    );

    final content = base64Encode(pdfBytes);
    html.AnchorElement(
      href: 'data:application/pdf;base64,$content',
    )
      ..setAttribute('download', '$fileName.pdf')
      ..click();

    return "$fileName.pdf";
  } catch (e) {
    debugPrint("Error exporting Pump Log matrix PDF Web: $e");
    return null;
  }
}
