class SensorHourReportGsm {
  final String hour;
  final String deviceSrNo;
  final String sensorSrNo;
  final String value;
  final String errorCode;
  final String minValue;
  final String maxValue;
  final String averageValue;
  final String? timeStamp;
  final String? wetHours;

  SensorHourReportGsm({
    required this.hour,
    required this.deviceSrNo,
    required this.sensorSrNo,
    required this.value,
    required this.errorCode,
    required this.minValue,
    required this.maxValue,
    required this.averageValue,
    this.timeStamp,
    this.wetHours,
  });

  @override
  String toString() =>
      '$hour -> value:$value min:$minValue max:$maxValue '
          'avg:$averageValue error:$errorCode wetHours:$wetHours timeStamp:$timeStamp';
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

  if (raw.trim().isEmpty) return zeroReport();
  String? timestamp;
  final at = raw.indexOf('@');
  if (at >= 0) {
    timestamp = raw.substring(at + 1).trim();
    raw = raw.substring(0, at);
  }
  final wantedSensor = double.tryParse(targetSensor);
  for (final deviceBlock in raw.split(';')) {
    final colon = deviceBlock.indexOf(':');
    if (colon < 0) continue;
    final deviceId = deviceBlock.substring(0, colon).split(',').first.trim();
    if (deviceId != deviceSrNo.trim()) continue;
    for (final sensorBlock in deviceBlock.substring(colon + 1).split('_')) {
      final fields = sensorBlock.split(',');
      if (fields.length < 5) continue;
      final sensorId = fields[0].trim();
      final parsedId = double.tryParse(sensorId);
      final matches = wantedSensor != null && parsedId != null
          ? (wantedSensor * 1000).round() == (parsedId * 1000).round()
          : sensorId == targetSensor.trim();
      if (!matches) continue;
      String field(int i) => i < fields.length && fields[i].trim().isNotEmpty
          ? fields[i].trim() : 'NA';
      final isLeaf = parsedId != null && (parsedId * 1000).round() == 37001;
      return SensorHourReportGsm(
        hour: hour,
        deviceSrNo: deviceId,
        sensorSrNo: sensorId,
        value: field(1),
        errorCode: field(2),
        minValue: field(3),
        maxValue: field(4),
        averageValue: field(5),
        wetHours: isLeaf && fields.length > 6 ? field(6) : null,
        timeStamp: timestamp,
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
  final result = <SensorHourReportGsm>[];
  final days = apiResponse['data'];
  if (days is! List) return result;
  for (final day in days) {
    if (day is! Map) continue;
    for (var i = 0; i < 24; i++) {
      final hour = '${i.toString().padLeft(2, '0')}:00';
      result.add(parseSensorHourData(
        raw: day[hour]?.toString() ?? '',
        hour: hour,
        deviceSrNo: targetDevice,
        targetSensor: targetSensor,
      )!);
    }
  }
  return result;
}
