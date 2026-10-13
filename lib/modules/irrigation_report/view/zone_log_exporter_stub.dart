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
  Map<String, int>? dailyTotalQuantities,
  required int grandTotalSeconds,
  int grandTotalQuantity = 0,
  required String fileName,
}) async {
  try {
    final excel = Excel.createExcel();
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final Sheet sheet = excel[defaultSheet];

    // Header 1: Date Headers
    List<CellValue> header1 = [TextCellValue('')];
    for (var d in dateColumns) {
      String dateStr = DateFormat('dd/MM/yyyy (E)').format(d);
      header1.add(TextCellValue(dateStr));
    }
    header1.add(TextCellValue('Total'));
    sheet.appendRow(header1);

    // Header 2: Sub-headers
    List<CellValue> header2 = [TextCellValue('Program / Sequence')];
    for (var _ in dateColumns) {
      header2.add(TextCellValue('Duration / Quantity'));
    }
    header2.add(TextCellValue('Total Duration / Quantity'));
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
      int rowTotalQty = 0;
      for (var d in dateColumns) {
        String dKey = DateFormat('yyyy-MM-dd').format(d);
        var dayData = row.dayEntries[dKey];
        if (dayData != null && dayData.hasRun) {
          int sec = (dayData.durationQtySeconds as int? ?? 0);
          int qtyVal = (dayData.quantityCompleted as int? ?? 0);
          String qtyStr = qtyVal > 0 ? qtyVal.toString() : '-';
          dataRow.add(TextCellValue("${dayData.durationQtyStr} / $qtyStr"));
          rowTotalSec += sec;
          rowTotalQty += qtyVal;
        } else {
          dataRow.add(TextCellValue('- / -'));
        }
      }
      String totalDur = _formatDurationHelper(rowTotalSec);
      String totalQty = rowTotalQty > 0 ? rowTotalQty.toString() : '-';
      dataRow.add(TextCellValue("$totalDur / $totalQty"));
      sheet.appendRow(dataRow);
    }

    // Footer Total Row
    List<CellValue> footerRow = [TextCellValue('Total')];
    for (var d in dateColumns) {
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      int daySec = dailyTotals[dKey] ?? 0;
      int dayQty = dailyTotalQuantities?[dKey] ?? 0;
      String dayDur = _formatDurationHelper(daySec);
      String dayQtyStr = dayQty > 0 ? dayQty.toString() : '-';
      footerRow.add(TextCellValue("$dayDur / $dayQtyStr"));
    }
    String gDur = _formatDurationHelper(grandTotalSeconds);
    String gQty = grandTotalQuantity > 0 ? grandTotalQuantity.toString() : '-';
    footerRow.add(TextCellValue("$gDur / $gQty"));
    sheet.appendRow(footerRow);

    final fileBytes = excel.encode();
    if (fileBytes == null) {
      debugPrint("Excel encode returned null");
      return null;
    }

    final Uint8List bytes = Uint8List.fromList(fileBytes);

    // 1. Try BetterDownloadSaver for mobile downloads
    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$fileName.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (savedPath != null && savedPath.isNotEmpty) {
        debugPrint(
            'Excel saved successfully via BetterDownloadSaver: $savedPath');
        return "$fileName.xlsx";
      }
    } catch (e, st) {
      debugPrint("BetterDownloadSaver error: $e\n$st");
    }

    // 2. Fallback to path_provider download directory
    try {
      Directory downloadDir = await _resolveDownloadDirectory();
      String xlsxPath = "${downloadDir.path}/$fileName.xlsx";
      File xlsxFile = File(xlsxPath);
      await xlsxFile.create(recursive: true);
      await xlsxFile.writeAsBytes(bytes);
      debugPrint('Excel saved successfully via File fallback: $xlsxPath');
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
