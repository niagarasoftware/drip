import 'dart:convert';
import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'zone_log_pdf_builder.dart';

Future<String?> exportZoneLogToCSV(List<dynamic> records, String fileName) async {
  try {
    StringBuffer sb = StringBuffer();
    sb.writeln('Date,Program Name,Sequence Name,HeadUnit,Pump,Start Time,End Time,Duration,Start Reason,End Reason');

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

      sb.writeln('"$dateStr","$progStr","$seqStr","$huStr","$pumpStr","$startStr","$endStr","$durStr","$startRStr","$endRStr"');
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

Future<String?> exportZoneLogToPDF(List<dynamic> records, String fileName) async {
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
  required int grandTotalSeconds,
  required String fileName,
}) async {
  try {
    final excel = Excel.createExcel();
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final Sheet sheet = excel[defaultSheet];

    // Header 1: Date Headers
    List<CellValue> header1 = [TextCellValue('Program / Sequence')];
    for (var d in dateColumns) {
      String dateStr = DateFormat('dd/MM/yyyy (E)').format(d);
      header1.add(TextCellValue(dateStr));
      header1.add(TextCellValue(''));
    }
    header1.add(TextCellValue('Total'));
    sheet.appendRow(header1);

    // Header 2: Sub-headers
    List<CellValue> header2 = [TextCellValue('Program / Sequence')];
    for (var _ in dateColumns) {
      header2.add(TextCellValue('Duration / Quantity'));
      header2.add(TextCellValue('Quantity Completed'));
    }
    header2.add(TextCellValue('Total Duration'));
    sheet.appendRow(header2);

    // Data rows
    for (var row in rows) {
      List<CellValue> dataRow = [];
      String displayName =
          (row.progName.isNotEmpty && row.progName != row.seqName)
              ? "${row.progName} - ${row.seqName}"
              : row.seqName;
      dataRow.add(TextCellValue(displayName));

      int rowTotalSec = 0;
      for (var d in dateColumns) {
        String dKey = DateFormat('yyyy-MM-dd').format(d);
        var dayData = row.dayEntries[dKey];
        if (dayData != null && dayData.hasRun) {
          dataRow.add(TextCellValue(dayData.durationQtyStr));
          dataRow.add(TextCellValue(dayData.qtyCompletedStr));
          rowTotalSec += (dayData.durationQtySeconds as int? ?? 0);
        } else {
          dataRow.add(TextCellValue('00:00:00'));
          dataRow.add(TextCellValue('0'));
        }
      }
      dataRow.add(TextCellValue(_formatDurationHelper(rowTotalSec)));
      sheet.appendRow(dataRow);
    }

    // Footer Total Row
    List<CellValue> footerRow = [TextCellValue('Total')];
    for (var d in dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySec = dailyTotals[dKey] ?? 0;
      footerRow.add(TextCellValue(_formatDurationHelper(daySec)));
      footerRow.add(TextCellValue(''));
    }
    footerRow.add(TextCellValue(_formatDurationHelper(grandTotalSeconds)));
    sheet.appendRow(footerRow);

    final fileBytes = excel.encode();
    if (fileBytes == null) return null;

    final content = base64Encode(fileBytes);
    html.AnchorElement(
      href: 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$content',
    )
      ..setAttribute('download', '$fileName.xlsx')
      ..click();

    return "$fileName.xlsx";
  } catch (e) {
    debugPrint("Error exporting Zone Log matrix to Excel Web: $e");
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
