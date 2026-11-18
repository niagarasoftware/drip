class TimeData {
  final String label;
  final DateTime onTime;
  final DateTime offTime;
  final Duration duration;

  TimeData({
    required this.label,
    required this.onTime,
    required this.offTime,
    required this.duration,
  });

  // Convert DateTime to minutes from the start of the day
  double get onTimeInMinutes => onTime.difference(DateTime(onTime.year, onTime.month, onTime.day)).inMinutes.toDouble();
  double get offTimeInMinutes => offTime.difference(DateTime(offTime.year, offTime.month, offTime.day)).inMinutes.toDouble();
  double get durationInMinutes => duration.inMinutes.toDouble();
}