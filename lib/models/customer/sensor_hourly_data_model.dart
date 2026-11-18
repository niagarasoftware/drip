class SensorHourlyDataModel {
  final String date;
  final Map<String, List<SensorHourlyData>> data;

  SensorHourlyDataModel({required this.date, required this.data});
}

class SensorHourlyData {
  final String sensorId;
  final String value;
  final String extra;
  final String hour;
  final DateTime date;

  SensorHourlyData({
    required this.sensorId,
    required this.value,
    required this.extra,
    required this.hour,
    required this.date,
  });

  factory SensorHourlyData.fromCsv(String csv, String hour, String dateStr) {
    final parts = csv.split(',');
    return SensorHourlyData(
      sensorId: parts[0],
      value: parts.length > 1 ? parts[1] : '',
      extra: parts.length > 2 ? parts[2] : '',
      hour: hour,
      date: DateTime.parse(dateStr),
    );
  }
}