import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:better_download_saver/better_download_saver.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'pump_log_csv_builder.dart';
import 'pump_log_excel_builder.dart';
import 'pump_log_pdf_builder.dart';

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

Future<bool> generatePumpLogExcel(
  PumpLogExportData data,
  String name,
) async {
  try {
    final Excel excel = buildPumpLogExcel(data);
    final fileBytes = excel.encode();

    if (fileBytes == null) {
      return false;
    }

    final Uint8List bytes = Uint8List.fromList(fileBytes);

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$name.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (savedPath != null && savedPath.isNotEmpty) {
        debugPrint('Excel saved successfully via BetterDownloadSaver: $savedPath');
        return true;
      }
    } catch (e) {
      debugPrint('BetterDownloadSaver Excel error: $e');
    }

    Directory downloadDir = await _resolveDownloadDirectory();
    String xlsxPath = "${downloadDir.path}/$name.xlsx";
    File file = File(xlsxPath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    debugPrint('Excel saved fallback: $xlsxPath');
    return true;
  } catch (e, stackTrace) {
    debugPrint('Error generating Excel: $e\n$stackTrace');
    return false;
  }
}

Future<bool> generatePumpLogCSV(
  PumpLogExportData data,
  String name,
) async {
  try {
    final csvStr = generatePumpLogCsvString(data);
    final bytes = Uint8List.fromList(utf8.encode(csvStr));

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$name.csv',
        bytes: bytes,
        mimeType: 'text/csv',
      );

      if (savedPath != null && savedPath.isNotEmpty) {
        debugPrint('CSV saved successfully via BetterDownloadSaver: $savedPath');
        return true;
      }
    } catch (e) {
      debugPrint('BetterDownloadSaver CSV error: $e');
    }

    Directory downloadDir = await _resolveDownloadDirectory();
    String csvPath = "${downloadDir.path}/$name.csv";
    File file = File(csvPath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    debugPrint('CSV saved fallback: $csvPath');
    return true;
  } catch (e, stackTrace) {
    debugPrint('Error generating CSV: $e\n$stackTrace');
    return false;
  }
}

Future<bool> generatePumpLogPDF(
  PumpLogExportData data,
  String name,
) async {
  try {
    final Uint8List bytes = generatePumpLogPdfBytes(data, name);

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$name.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );

      if (savedPath != null && savedPath.isNotEmpty) {
        debugPrint('PDF saved successfully via BetterDownloadSaver: $savedPath');
        return true;
      }
    } catch (e) {
      debugPrint('BetterDownloadSaver PDF error: $e');
    }

    Directory downloadDir = await _resolveDownloadDirectory();
    String pdfPath = "${downloadDir.path}/$name.pdf";
    File file = File(pdfPath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    debugPrint('PDF saved fallback: $pdfPath');
    return true;
  } catch (e, stackTrace) {
    debugPrint('Error generating PDF: $e\n$stackTrace');
    return false;
  }
}
