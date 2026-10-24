import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
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

    final content = base64Encode(fileBytes);
    html.AnchorElement(
      href:
          'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$content',
    )
      ..setAttribute('download', '$name.xlsx')
      ..click();

    return true;
  } catch (e) {
    debugPrint("Error exporting Standalone Excel Web: $e");
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
    final content = base64Encode(bytes);

    html.AnchorElement(
      href: 'data:application/pdf;base64,$content',
    )
      ..setAttribute('download', '$name.pdf')
      ..click();

    return true;
  } catch (e) {
    debugPrint("Error exporting Standalone PDF Web: $e");
    return false;
  }
}
