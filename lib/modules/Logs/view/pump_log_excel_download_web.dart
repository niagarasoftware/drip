import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'pump_log_csv_builder.dart';
import 'pump_log_excel_builder.dart';
import 'pump_log_pdf_builder.dart';

/// Blob-based download: works for large files (a base64 data: URI can fail for big PDFs).
void _download(List<int> bytes, String fileName, String mimeType) {
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

Future<bool> generatePumpLogExcel(PumpLogExportData data, String name) async {
  try {
    final Excel excel = buildPumpLogExcel(data);
    final fileBytes = excel.encode();
    if (fileBytes == null) return false;
    _download(fileBytes, '$name.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    return true;
  } catch (e, stackTrace) {
    print('Error generating Excel web: $e\n$stackTrace');
    return false;
  }
}

Future<bool> generatePumpLogCSV(PumpLogExportData data, String name) async {
  try {
    final csvStr = generatePumpLogCsvString(data);
    _download(utf8.encode(csvStr), '$name.csv', 'text/csv;charset=utf-8');
    return true;
  } catch (e, stackTrace) {
    print('Error generating CSV web: $e\n$stackTrace');
    return false;
  }
}

Future<bool> generatePumpLogPDF(PumpLogExportData data, String name) async {
  try {
    final pdfBytes = await generatePumpLogPdfBytes(data, name);
    _download(pdfBytes, '$name.pdf', 'application/pdf');
    return true;
  } catch (e, stackTrace) {
    print('Error generating PDF web: $e\n$stackTrace');
    return false;
  }
}