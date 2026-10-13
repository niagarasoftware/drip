import 'dart:html' as html;
import 'dart:typed_data';

class WeatherExcelSaveResult {
  final String fileName;
  final String location;
  final String message;
  const WeatherExcelSaveResult(this.fileName, this.location, this.message);
}

Future<WeatherExcelSaveResult> saveWeatherExcel(Uint8List bytes, String name) async {
  final blob = html.Blob([bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..download = name;
  try {
    anchor.click();
  } finally {
    html.Url.revokeObjectUrl(url);
  }
  // Browsers do not expose the final filesystem path or download completion.
  return WeatherExcelSaveResult(name, 'Browser Downloads (or browser-selected folder)',
      'Weather report download started');
}
