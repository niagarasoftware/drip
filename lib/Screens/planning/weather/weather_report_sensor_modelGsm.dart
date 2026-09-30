class SensorHourReportGsm {
  final String hour;
  final String deviceSrNo;
  final String sensorSrNo;
  final String value;
  final String errorCode;
  final String minValue;
  final String maxValue;
  final String averageValue;

  SensorHourReportGsm({
    required this.hour,
    required this.deviceSrNo,
    required this.sensorSrNo,
    required this.value,
    required this.errorCode,
    required this.minValue,
    required this.maxValue,
    required this.averageValue,
  });

  @override
  String toString() {
    return '$hour → value:$value min:$minValue max:$maxValue avg:$averageValue error:$errorCode';
  }
}
SensorHourReportGsm? parseSensorHourData({
  required String raw,
  required String hour,
  required String deviceSrNo,
  required String targetSensor,
}) {

  SensorHourReportGsm zeroReport() => SensorHourReportGsm(
    hour: hour,
    deviceSrNo: deviceSrNo,
    sensorSrNo: targetSensor,
    value: 'NA',
    errorCode: 'NA',
    minValue: 'NA',
    maxValue: 'NA',
    averageValue: 'NA',
  );
  if (raw == null || raw.trim().isEmpty) return zeroReport();

  // 1️⃣ Split devices
  final deviceBlocks = raw.split(';');
  print("deviceBlocks:$deviceBlocks");

  for (final deviceBlock in deviceBlocks) {
    if (deviceBlock == null || !deviceBlock.contains(':')) continue;

    final deviceParts = deviceBlock.split(':');
    if (deviceParts.length < 2) continue;
    print("deviceParts:$deviceParts");


    final sensorsRaw = deviceParts[1];
    if (sensorsRaw == null) continue;
    print("sensorsRaw:$sensorsRaw");
    // 3️⃣ Split sensors
    final sensorBlocks = sensorsRaw.split('_');
    print("sensorBlocks:$sensorBlocks");
    for (final sensorBlock in sensorBlocks) {
      if (sensorBlock == null) continue;
      final parts = sensorBlock.split(',');

      if (parts.length < 5) continue;

      final sensorSrNo = parts[0]?.trim() ?? "";

      // 4️⃣ Match sensor
      if (sensorSrNo != targetSensor) continue;

      String v(int i) => (i < parts.length && parts[i] != null && parts[i].trim().isNotEmpty) ? parts[i].trim() : '0';
      final averageValue =
      parts.length > 5 && parts[5].trim().isNotEmpty
          ? parts[5].trim()
          : 'NA';

      // 5️⃣ Create report
      return SensorHourReportGsm(
        hour: hour,
        deviceSrNo: deviceSrNo,
        sensorSrNo: sensorSrNo,
        value: v(1),
        errorCode: v(2),
        minValue: v(3),
        maxValue: v(4),
        averageValue: averageValue,
      );
    }
  }

  return zeroReport();
}

List<SensorHourReportGsm> getSingleSensorReport({
  required Map<String, dynamic> apiResponse,
  required String targetDevice,
  required String targetSensor,
}) {
  final List<SensorHourReportGsm> report = [];

  if (apiResponse['data'] == null || apiResponse['data'].isEmpty) {
    return report;
  }

  final Map<String, dynamic> dayData = apiResponse['data'][0];

  dayData.forEach((key, value) {
    // skip date & empty hours
    if (key == 'date' || !key.contains(':')) return;
    if (value == null || value.toString().trim().isEmpty) return;

    final String hour = key;

    // 1️⃣ ; → device blocks
    final deviceBlocks = value.toString().split(';');

    for (final block in deviceBlocks) {
      print("block:$block");
      if (!block.contains(':')) continue;

      // 2️⃣ match device
      final deviceSplit = block.split(':');
      print("deviceSplit:$deviceSplit");

      if (deviceSplit.length != 2) continue;

      final deviceId = deviceSplit[0].trim();
      if (deviceId != targetDevice) continue;

      // 3️⃣ _ → sensor blocks
      final sensors = deviceSplit[1].split('_');
      print("sensors:$sensors");

      for (final sensorRaw in sensors) {
        // 4️⃣ , → values (inside parseSensorRecord)
        final parsed = parseSensorHourData(
          raw: sensorRaw,
          hour: hour,
          deviceSrNo: deviceId,
          targetSensor: targetSensor,
        );

        if (parsed != null) {
          report.add(parsed);
        }
      }
    }
  });

  return report;
}

