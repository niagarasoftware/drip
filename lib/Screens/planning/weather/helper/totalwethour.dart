
int wetDurationToMinutes(String? duration) {
  if (duration == null || duration == 'NA') return 0;

  final parts = duration.trim().split(RegExp(r'[.:]'));
  if (parts.length != 2) return 0;

  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;

  if (minutes < 0 || minutes >= 60) return 0;

  return hours * 60 + minutes;
}

String minutesToWetDuration(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}';
}

String calculateTotalWetDuration(
    List<String> dailyWetDurations,
    ) {
  final totalMinutes = dailyWetDurations.fold<int>(
    0,
        (sum, duration) => sum + wetDurationToMinutes(duration),
  );

  return minutesToWetDuration(totalMinutes);
}
