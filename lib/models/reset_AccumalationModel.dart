// To parse this JSON data, do
//
//     final resetModel = resetModelFromJson(jsonString);

import 'dart:convert';

ResetModel resetModelFromJson(String str) => ResetModel.fromJson(json.decode(str));

String resetModelToJson(ResetModel data) => json.encode(data.toJson());

class ResetModel {
  int? code;
  String? message;
  Data? data;

  ResetModel({
    this.code,
    this.message,
    this.data,
  });

  factory ResetModel.fromJson(Map<String, dynamic> json) => ResetModel(
    code: json["code"],
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  List<Accumulation>? accumulation;
  Default? dataDefault;

  Data({
    this.accumulation,
    this.dataDefault,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    accumulation: json["accumulation"] == null ? [] : List<Accumulation>.from(json["accumulation"]!.map((x) => Accumulation.fromJson(x))),
    dataDefault: json["default"] == null ? null : Default.fromJson(json["default"]),
  );

  Map<String, dynamic> toJson() => {
    "accumulation": accumulation == null ? [] : List<dynamic>.from(accumulation!.map((x) => x.toJson())),
    "default": dataDefault?.toJson(),
  };
}

class Accumulation {
  String? name;
  List<ListElement>? list;

  Accumulation({
    this.name,
    this.list,
  });

  factory Accumulation.fromJson(Map<String, dynamic> json) => Accumulation(
    name: json["name"],
    list: json["list"] == null ? [] : List<ListElement>.from(json["list"]!.map((x) => ListElement.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "list": list == null ? [] : List<dynamic>.from(list!.map((x) => x.toJson())),
  };
}

class ListElement {
  double? sNo;
  String? name;
  double? location;
  String? todayCumulativeFlow;
  String? totalCumulativeFlow;

  ListElement({
    this.sNo,
    this.name,
    this.location,
    this.todayCumulativeFlow,
    this.totalCumulativeFlow,
  });

  factory ListElement.fromJson(Map<String, dynamic> json) => ListElement(
    sNo: json["sNo"],
    name: json["name"],
    location: json["location"],
    todayCumulativeFlow: json["todayCumulativeFlow"],
    totalCumulativeFlow: json["totalCumulativeFlow"],
  );

  Map<String, dynamic> toJson() => {
    "sNo": sNo,
    "name": name,
    "location": location,
    "todayCumulativeFlow": todayCumulativeFlow,
    "totalCumulativeFlow": totalCumulativeFlow,
  };
}

class Default {
  String? data;

  Default({
    this.data,
  });

  factory Default.fromJson(Map<String, dynamic> json) => Default(
    data: json["data"],
  );

  Map<String, dynamic> toJson() => {
    "data": data,
  };
}