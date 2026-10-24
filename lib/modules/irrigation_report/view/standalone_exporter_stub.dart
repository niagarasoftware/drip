import 'dart:io';
import 'dart:typed_data';
import 'package:better_download_saver/better_download_saver.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'irrigation_log_pdf_builder.dart';

Future<bool> exportStandaloneExcel(
  Map<String, dynamic> data,
  List<String> standaloneColumn,
  String name,
) async {
  try {
    final fixedCols = data['fixedColumnData'] as List? ?? [];
    final standaloneCols = data['standaloneColumnData'] as List? ?? [];

    if (fixedCols.isEmpty) {
      return false;
    }

    var excel = Excel.createExcel();
    var sheetName = excel.getDefaultSheet() ?? 'Logs';
    Sheet sheetObject = excel[sheetName];

    List<String> headerRow = ['Date', ...standaloneColumn];
    sheetObject.appendRow([for (var col in headerRow) TextCellValue(col)]);

    for (var i = 0; i < fixedCols.length; i++) {
      final dateVal = '${fixedCols[i] ?? '-'}';
      List<String> eachRow = [dateVal];

      if (i < standaloneCols.length && standaloneCols[i] is List) {
        final rowItems = standaloneCols[i] as List;
        for (var item in rowItems) {
          eachRow.add('${item ?? '-'}');
        }
      }

      sheetObject.appendRow([for (var cell in eachRow) TextCellValue(cell)]);
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) return false;

    final bytes = Uint8List.fromList(fileBytes);

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$name.xlsx',
        bytes: bytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (savedPath != null && savedPath.isNotEmpty) {
        return true;
      }
    } catch (e) {
      debugPrint('BetterDownloadSaver error: $e');
    }

    try {
      const dirPath = "/storage/emulated/0/Download";
      final file = File("$dirPath/$name.xlsx");
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return await file.exists();
    } catch (e) {
      debugPrint('Direct file save error: $e');
    }

    return false;
  } catch (e) {
    debugPrint("Error exporting Standalone Excel stub: $e");
    return false;
  }
}

Future<bool> exportStandalonePdf(
  Map<String, dynamic> data,
  List<String> standaloneColumn,
  String name,
) async {
  try {
    final fixedCols = data['fixedColumnData'] as List? ?? [];
    final standaloneCols = data['standaloneColumnData'] as List? ?? [];

    if (fixedCols.isEmpty) {
      return false;
    }

    final Map<String, dynamic> reportData = {
      'fixedColumn': 'Date',
      'fixedColumnData': fixedCols,
      'generalColumn': standaloneColumn,
      'generalColumnData': List.generate(standaloneColumn.length, (colIdx) {
        return List.generate(fixedCols.length, (rowIdx) {
          if (rowIdx < standaloneCols.length && standaloneCols[rowIdx] is List) {
            final rowItems = standaloneCols[rowIdx] as List;
            return colIdx < rowItems.length ? rowItems[colIdx] : '-';
          }
          return '-';
        });
      }),
    };

    final Uint8List bytes = generateIrrigationLogPdfBytes(reportData, name);

    try {
      final saver = BetterDownloadSaver();
      final String? savedPath = await saver.saveToDownloads(
        fileName: '$name.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      if (savedPath != null && savedPath.isNotEmpty) {
        return true;
      }
    } catch (e) {
      debugPrint('BetterDownloadSaver PDF error: $e');
    }

    try {
      const dirPath = "/storage/emulated/0/Download";
      final file = File("$dirPath/$name.pdf");
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return await file.exists();
    } catch (e) {
      debugPrint('Direct PDF file save error: $e');
    }

    return false;
  } catch (e) {
    debugPrint("Error exporting Standalone PDF stub: $e");
    return false;
  }
}
