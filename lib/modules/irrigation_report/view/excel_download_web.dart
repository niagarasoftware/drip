import 'dart:convert';
import 'dart:html' as html;
import 'excel_builder.dart';

/// This file is selected by the conditional import in log_home.dart when
/// `dart.library.html` is available (i.e. Flutter web builds). It must stay
/// in sync with excel_download_stub.dart's non-web counterpart.
///
/// IMPORTANT: both header row and data rows are built by buildLogsExcel()
/// from the SAME column-group list, so they can never drift out of sync.
/// Do not go back to building the header row and data rows from separately
/// filtered lists (e.g. 'xColumn' vs 'xColumnData') - that mismatch was the
/// root cause of the "RangeError: no indices are valid: 0" crash, since a
/// group's label list and its data list could end up with different
/// lengths depending on which columns the user had toggled on.
Future<bool> generateExcel(Map<String, dynamic> data, String name) async {
  try {
    final excel = buildLogsExcel(data);

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