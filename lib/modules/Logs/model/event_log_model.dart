class EventLog {
  final String onReason;
  final String offReason;
  final String onTime;
  final String offTime;
  final String duration;
  final bool isValve;

  EventLog({
    required this.onReason,
    required this.offReason,
    required this.onTime,
    required this.offTime,
    required this.duration,
    required this.isValve,
  });

  factory EventLog.fromJson(String data) {
    print("data : $data");
    return EventLog(
      onReason: data.split(",")[0],
      onTime: data.split(",")[1],
      offReason: data.split(",")[2],
      offTime: data.split(",")[3],
      duration: data.split(",")[4],
      isValve: data.split(",")[0].isNotEmpty ? data.split(",")[5].split(' ')[0] == "021" : false,
    );
  }
}