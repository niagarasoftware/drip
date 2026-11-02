import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'excel_builder.dart';
import 'irrigation_log_pdf_builder.dart';

Future<bool> generateExcel(dynamic data, String name) async {
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

    // Save the file
    var fileBytes = excel.encode();
    if (fileBytes != null) {
      // Encode bytes to base64
      final content = base64Encode(fileBytes);

      // Create a download link
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
    print('Error generating Excel: $e');
    print('stackTrace generating Excel: $stackTrace');
    return false;
  }
}

Future<bool> generatePdf(dynamic data, String name) async {
  try {
    final Uint8List bytes = generateIrrigationLogPdfBytes(data, name);
    final content = base64Encode(bytes);

    html.AnchorElement(
      href: 'data:application/pdf;base64,$content',
    )
      ..setAttribute('download', '$name.pdf')
      ..click();

    return true;
  } catch (e, stackTrace) {
    print('Error generating PDF Web: $e');
    print('stackTrace generating PDF Web: $stackTrace');
    return false;
  }
}
