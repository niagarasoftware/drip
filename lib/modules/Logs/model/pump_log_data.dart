import 'event_log_model.dart';

class PumpLogData {
  final String date;
  // final MotorLogs log;
  final List<EventLog> motor1;
  final List<EventLog> motor2;
  final List<EventLog> motor3;

  PumpLogData({required this.date, required this.motor1, required this.motor2, required this.motor3});

  factory PumpLogData.fromJson(Map<String, dynamic> json) {
    return PumpLogData(
      date: json['logDate'],
      // log: MotorLogs.fromJson(json['log']),
      motor1: (json['motor1'] as List<dynamic>).where((e) => validate(e))
          .map((e) => EventLog.fromJson(e as String))
          .toList(),
      motor2: (json['motor2'] as List<dynamic>).where((e) => validate(e))
          .map((e) => EventLog.fromJson(e as String))
          .toList(),
      motor3: (json['motor3'] as List<dynamic>).where((e) => validate(e))
          .map((e) => EventLog.fromJson(e as String))
          .toList(),
    );
  }

  static bool validate(String data){
    List<String> splitData = data.split(',');
    if(splitData[0].isNotEmpty){
      return splitData.length == 6;
    }else{
      return splitData.length == 5;
    }
  }
}
