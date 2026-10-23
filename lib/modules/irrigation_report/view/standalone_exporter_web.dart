import 'dart:convert';
import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

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
