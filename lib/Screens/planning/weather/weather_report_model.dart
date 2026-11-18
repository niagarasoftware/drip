// To parse this JSON data, do
//
//     final weatherReportModel = weatherReportModelFromJson(jsonString);

import 'dart:convert';

WeatherReportModel weatherReportModelFromJson(String str) => WeatherReportModel.fromJson(json.decode(str));

String weatherReportModelToJson(WeatherReportModel data) => json.encode(data.toJson());

class WeatherReportModel {
  int code;
  String message;
  List<Datum> data;

  WeatherReportModel({
    required this.code,
    required this.message,
    required this.data,
  });

  factory WeatherReportModel.fromJson(Map<String, dynamic> json) => WeatherReportModel(
    code: json["code"] ?? 0,
    message: json["message"] ?? "",
    data: json["data"] != null && json["data"] is List
        ? List<Datum>.from(json["data"].map((x) => Datum.fromJson(x)))
        : [],
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Datum {
  String date;
  String the0100;
  String the0200;
  String the0300;
  String the0400;
  String the0500;
  String the0600;
  String the0700;
  String the0800;
  String the0900;
  String the1000;
  String the1100;
  String the1200;
  String the1300;
  String the1400;
  String the1500;
  String the1600;
  String the1700;
  String the1800;
  String the1900;
  String the2000;
  String the2100;
  String the2200;
  String the2300;
  String the0000;

  Datum({
    required this.date,
    required this.the0100,
    required this.the0200,
    required this.the0300,
    required this.the0400,
    required this.the0500,
    required this.the0600,
    required this.the0700,
    required this.the0800,
    required this.the0900,
    required this.the1000,
    required this.the1100,
    required this.the1200,
    required this.the1300,
    required this.the1400,
    required this.the1500,
    required this.the1600,
    required this.the1700,
    required this.the1800,
    required this.the1900,
    required this.the2000,
    required this.the2100,
    required this.the2200,
    required this.the2300,
    required this.the0000,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    date: json["date"] ?? "",
    the0100: json["01:00"] ?? "",
    the0200: json["02:00"] ?? "",
    the0300: json["03:00"] ?? "",
    the0400: json["04:00"] ?? "",
    the0500: json["05:00"] ?? "",
    the0600: json["06:00"] ?? "",
    the0700: json["07:00"] ?? "",
    the0800: json["08:00"] ?? "",
    the0900: json["09:00"] ?? "",
    the1000: json["10:00"] ?? "",
    the1100: json["11:00"] ?? "",
    the1200: json["12:00"] ?? "",
    the1300: json["13:00"] ?? "",
    the1400: json["14:00"] ?? "",
    the1500: json["15:00"] ?? "",
    the1600: json["16:00"] ?? "",
    the1700: json["17:00"] ?? "",
    the1800: json["18:00"] ?? "",
    the1900: json["19:00"] ?? "",
    the2000: json["20:00"] ?? "",
    the2100: json["21:00"] ?? "",
    the2200: json["22:00"] ?? "",
    the2300: json["23:00"] ?? "",
    the0000: json["00:00"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "date": date,
    "01:00": the0100,
    "02:00": the0200,
    "03:00": the0300,
    "04:00": the0400,
    "05:00": the0500,
    "06:00": the0600,
    "07:00": the0700,
    "08:00": the0800,
    "09:00": the0900,
    "10:00": the1000,
    "11:00": the1100,
    "12:00": the1200,
    "13:00": the1300,
    "14:00": the1400,
    "15:00": the1500,
    "16:00": the1600,
    "17:00": the1700,
    "18:00": the1800,
    "19:00": the1900,
    "20:00": the2000,
    "21:00": the2100,
    "22:00": the2200,
    "23:00": the2300,
    "00:00": the0000,
  };
}
