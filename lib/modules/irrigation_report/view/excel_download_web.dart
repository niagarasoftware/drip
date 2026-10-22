import 'dart:convert';
import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'excel_builder.dart';

/// This file is selected by the conditional import in log_home.dart when
/// `dart.library.html` is available (i.e. Flutter web builds). It must stay
/// in sync with excel_download_stub.dart's non-web counterpart.
///
/// IMPORTANT: both header row and data rows are built by buildLogsExcel()
/// from the SAME column-group list, so they can never drift out of sync.
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
