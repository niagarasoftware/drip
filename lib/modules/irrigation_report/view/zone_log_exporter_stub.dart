import 'dart:io';
import 'package:better_download_saver/better_download_saver.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'zone_log_pdf_builder.dart';

Future<Directory> _resolveDownloadDirectory() async {
  Directory? directory;
  try {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        directory = await getDownloadsDirectory();
      } catch (_) {}

      if (directory == null) {
        try {
          final extDirs = await getExternalStorageDirectories(
              type: StorageDirectory.downloads);
          if (extDirs != null && extDirs.isNotEmpty) {
            directory = extDirs.first;
          }
        } catch (_) {}
      }

      if (directory == null) {
        final directDownload = Directory('/storage/emulated/0/Download');
        if (await directDownload.exists()) {
          directory = directDownload;
        }
      }
    } else if (!kIsWeb && Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else if (!kIsWeb) {
      try {
        directory = await getDownloadsDirectory();
      } catch (_) {}
    }
  } catch (e) {
    debugPrint("Error resolving download directory: $e");
  }

  directory ??= await getApplicationDocumentsDirectory();
  return directory;
}

Future<String?> exportZoneLogToCSV(
    List<dynamic> records, String fileName) async {
  try {
    final excel = Excel.createExcel();
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final Sheet sheet = excel[defaultSheet];

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Program Name'),
      TextCellValue('Sequence Name'),
      TextCellValue('HeadUnit'),
      TextCellValue('Pump'),
      TextCellValue('Start Time'),
      TextCellValue('End Time'),
      TextCellValue('Duration'),
      TextCellValue('Start Reason'),
      TextCellValue('End Reason'),
    ]);

    for (var rec in records) {
      sheet.appendRow([
        TextCellValue(rec.dateStr?.toString() ?? ''),
        TextCellValue(rec.programTitle?.toString() ?? ''),
        TextCellValue(rec.sequenceTitle?.toString() ?? ''),
        TextCellValue(rec.headUnit?.toString() ?? ''),
        TextCellValue(rec.pump?.toString() ?? ''),
        TextCellValue(rec.startTime?.toString() ?? ''),
        TextCellValue(rec.endTime?.toString() ?? ''),
        TextCellValue(rec.duration?.toString() ?? ''),
        TextCellValue(rec.startReason?.toString() ?? ''),
        TextCellValue(rec.endReason?.toString() ?? ''),
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) return null;
    final Uint8List bytes = Uint8List.fromList(fileBytes);

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$fileName.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (savedPath != null && savedPath.isNotEmpty) {
        return "$fileName.xlsx";
      }
    } catch (e) {
      debugPrint("BetterDownloadSaver error in exportZoneLogToCSV: $e");
    }

    Directory downloadDir = await _resolveDownloadDirectory();
    String xlsxPath = "${downloadDir.path}/$fileName.xlsx";
    File xlsxFile = File(xlsxPath);
    await xlsxFile.create(recursive: true);
    await xlsxFile.writeAsBytes(bytes);

    return "$fileName.xlsx";
  } catch (e) {
    debugPrint("Error exporting Excel/CSV: $e");
    return null;
  }
}

Future<String?> exportZoneLogToPDF(
    List<dynamic> records, String fileName) async {
  try {
    final pdfBytes = generateZoneLogPdfBytes(records, fileName);
    final Uint8List bytes = Uint8List.fromList(pdfBytes);

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$fileName.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      if (savedPath != null && savedPath.isNotEmpty) {
        return "$fileName.pdf";
      }
    } catch (e) {
      debugPrint("BetterDownloadSaver error in exportZoneLogToPDF: $e");
    }

    Directory downloadDir = await _resolveDownloadDirectory();
    String pdfPath = "${downloadDir.path}/$fileName.pdf";
    File pdfFile = File(pdfPath);
    await pdfFile.create(recursive: true);
    await pdfFile.writeAsBytes(bytes);

    return "$fileName.pdf";
  } catch (e) {
    debugPrint("Error exporting PDF: $e");
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
    if (fileBytes == null) {
      return null;
    }

    final Uint8List bytes = Uint8List.fromList(fileBytes);

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$fileName.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (savedPath != null && savedPath.isNotEmpty) {
        return "$fileName.xlsx";
      }
    } catch (e, st) {
      debugPrint("BetterDownloadSaver error: $e\n$st");
    }

    try {
      Directory downloadDir = await _resolveDownloadDirectory();
      String xlsxPath = "${downloadDir.path}/$fileName.xlsx";
      File xlsxFile = File(xlsxPath);
      await xlsxFile.create(recursive: true);
      await xlsxFile.writeAsBytes(bytes);
      return "$fileName.xlsx";
    } catch (e, st) {
      debugPrint("File fallback error: $e\n$st");
    }

    return null;
  } catch (e, st) {
    debugPrint("Error exporting Zone Log matrix to Excel: $e\n$st");
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

    final Uint8List bytes = Uint8List.fromList(pdfBytes);

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$fileName.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      if (savedPath != null && savedPath.isNotEmpty) {
        return "$fileName.pdf";
      }
    } catch (e) {
      debugPrint("BetterDownloadSaver error in exportZoneLogMatrixToPdf: $e");
    }

    Directory downloadDir = await _resolveDownloadDirectory();
    String pdfPath = "${downloadDir.path}/$fileName.pdf";
    File pdfFile = File(pdfPath);
    await pdfFile.create(recursive: true);
    await pdfFile.writeAsBytes(bytes);

    return "$fileName.pdf";
  } catch (e) {
    debugPrint("Error exporting Zone Log matrix PDF: $e");
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
    final Uint8List bytes = Uint8List.fromList(fileBytes);

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$fileName.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (savedPath != null && savedPath.isNotEmpty) {
        return "$fileName.xlsx";
      }
    } catch (e, st) {
      debugPrint(
          "BetterDownloadSaver error in exportPumpLogMatrixToExcel: $e\n$st");
    }

    try {
      Directory downloadDir = await _resolveDownloadDirectory();
      String xlsxPath = "${downloadDir.path}/$fileName.xlsx";
      File xlsxFile = File(xlsxPath);
      await xlsxFile.create(recursive: true);
      await xlsxFile.writeAsBytes(bytes);
      return "$fileName.xlsx";
    } catch (e, st) {
      debugPrint("File fallback error in exportPumpLogMatrixToExcel: $e\n$st");
    }

    return null;
  } catch (e, st) {
    debugPrint("Error exporting Pump Log matrix to Excel: $e\n$st");
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

    final Uint8List bytes = Uint8List.fromList(pdfBytes);

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$fileName.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      if (savedPath != null && savedPath.isNotEmpty) {
        return "$fileName.pdf";
      }
    } catch (e) {
      debugPrint("BetterDownloadSaver error in exportPumpLogMatrixToPdf: $e");
    }

    Directory downloadDir = await _resolveDownloadDirectory();
    String pdfPath = "${downloadDir.path}/$fileName.pdf";
    File pdfFile = File(pdfPath);
    await pdfFile.create(recursive: true);
    await pdfFile.writeAsBytes(bytes);

    return "$fileName.pdf";
  } catch (e) {
    debugPrint("Error exporting Pump Log matrix PDF: $e");
    return null;
  }
}
