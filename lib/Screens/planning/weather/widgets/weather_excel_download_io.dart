import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class WeatherExcelSaveResult {
  final String fileName;
  final String location;
  final String message;

  const WeatherExcelSaveResult(
      this.fileName,
      this.location,
      this.message,
      );
}

Future<WeatherExcelSaveResult> saveWeatherExcel(
    Uint8List bytes,
    String name,
    ) async {
  final safeName = name.replaceAll(':', '-');

  try {
    if (Platform.isAndroid) {
      print("call isAndroid");
      final downloadsPath = '/storage/emulated/0/Download';
      final file = File('$downloadsPath/$safeName');

      await file.writeAsBytes(bytes, flush: true);

      return WeatherExcelSaveResult(
        safeName,
        file.path,
        'Weather report downloaded successfully',
      );
    }

    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}${Platform.pathSeparator}$safeName',
    );

    await file.writeAsBytes(bytes, flush: true);

    return WeatherExcelSaveResult(
      safeName,
      file.path,
      'Weather report saved successfully',
    );
  } catch (e) {
    throw Exception('Excel download failed: $e');
  }
}