import 'dart:convert';
import 'dart:html' as html;

import 'package:excel/excel.dart';

import 'pump_log_csv_builder.dart';
import 'pump_log_excel_builder.dart';
import 'pump_log_pdf_builder.dart';

Future<bool> generatePumpLogExcel(PumpLogExportData data, String name) async {
  try {
    final Excel excel = buildPumpLogExcel(data);
    var fileBytes = excel.encode();
    if (fileBytes != null) {
      final content = base64Encode(fileBytes);
      final anchor = html.AnchorElement(
        href:
            'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$content',
      )
        ..setAttribute('download', '$name.xlsx')
        ..click();

      return true;
    } else {
      return false;
    }
  } catch (e, stackTrace) {
    print('Error generating Excel web: $e\n$stackTrace');
    return false;
  }
}

Future<bool> generatePumpLogCSV(PumpLogExportData data, String name) async {
  try {
    final csvStr = generatePumpLogCsvString(data);
    final bytes = utf8.encode(csvStr);
    final content = base64Encode(bytes);
    html.AnchorElement(
      href: 'data:text/csv;charset=utf-8;base64,$content',
    )
      ..setAttribute('download', '$name.csv')
      ..click();

    return true;
  } catch (e, stackTrace) {
    print('Error generating CSV web: $e\n$stackTrace');
    return false;
  }
}

Future<bool> generatePumpLogPDF(PumpLogExportData data, String name) async {
  try {
    final pdfBytes = generatePumpLogPdfBytes(data, name);
    final content = base64Encode(pdfBytes);
    html.AnchorElement(
      href: 'data:application/pdf;base64,$content',
    )
      ..setAttribute('download', '$name.pdf')
      ..click();

    return true;
  } catch (e, stackTrace) {
    print('Error generating PDF web: $e\n$stackTrace');
    return false;
  }
}
