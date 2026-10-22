import 'dart:typed_data';

import 'package:better_download_saver/better_download_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:excel/excel.dart';

import 'excel_builder.dart';

Future<bool> generateExcel(
    dynamic data,
    String name,
    ) async {
  try {
    final Excel excel;
    if (data is Map<String, Map<String, dynamic>>) {
      excel = buildMultiSheetLogsExcel(data);
    } else if (data is Map<String, dynamic>) {
      bool isMultiSheet = data.isNotEmpty && data.values.every((v) => v is Map);
      if (isMultiSheet) {
        excel = buildMultiSheetLogsExcel(data.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))));
      } else {
        excel = buildLogsExcel(data);
      }
    } else {
      return false;
    }

    final fileBytes = excel.encode();

    if (fileBytes == null) {
      return false;
    }

    final Uint8List bytes = Uint8List.fromList(fileBytes);

    final saver = BetterDownloadSaver();

    final String? savedPath = await saver.saveToDownloads(
      fileName: '$name.xlsx',
      bytes: bytes,
      mimeType:
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    if (savedPath == null) {
      debugPrint('Excel save failed');
      return false;
    }

    debugPrint('Excel saved successfully: $savedPath');

    return true;
  } catch (e, stackTrace) {
    debugPrint('Error generating Excel: $e');
    debugPrint('StackTrace generating Excel: $stackTrace');
    return false;
  }
}
