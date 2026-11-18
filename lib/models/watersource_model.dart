// To parse this JSON data, do
//
//     final waterSourceModel = waterSourceModelFromJson(jsonString);

import 'dart:convert';

WaterSourceModel waterSourceModelFromJson(String str) => WaterSourceModel.fromJson(json.decode(str));

String waterSourceModelToJson(WaterSourceModel data) => json.encode(data.toJson());

class WaterSourceModel {
  int? code;
  String? message;
  Data? data;

  WaterSourceModel({
    this.code,
    this.message,
    this.data,
  });

  factory WaterSourceModel.fromJson(Map<String, dynamic> json) => WaterSourceModel(
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
  List<WaterSource>? waterSource;
  String? controllerReadStatus;

  Data({
    this.waterSource,
    this.controllerReadStatus,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    waterSource: json["waterSource"] == null ? [] : List<WaterSource>.from(json["waterSource"]!.map((x) => WaterSource.fromJson(x))),
    controllerReadStatus: json["controllerReadStatus"],
  );

  Map<String, dynamic> toJson() => {
    "waterSource": waterSource == null ? [] : List<dynamic>.from(waterSource!.map((x) => x.toJson())),
    "controllerReadStatus": controllerReadStatus,
  };
}

class WaterSource {
  int? objectId;
  double? sNo;
  String? name;
  String? objectName;
  List<Setting>? setting;

  WaterSource({
    this.objectId,
    this.sNo,
    this.name,
    this.objectName,
    this.setting,
  });

  factory WaterSource.fromJson(Map<String, dynamic> json) => WaterSource(
    objectId: json["objectId"],
    sNo: json["sNo"]?.toDouble(),
    name: json["name"],
    objectName: json["objectName"],
    setting: json["setting"] == null ? [] : List<Setting>.from(json["setting"]!.map((x) => Setting.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "objectId": objectId,
    "sNo": sNo,
    "name": name,
    "objectName": objectName,
    "setting": setting == null ? [] : List<dynamic>.from(setting!.map((x) => x.toJson())),
  };
}

class Setting {
  int? sNo;
  String? title;
  int? widgetTypeId;
  String? iconCodePoint;
  String? iconFontFamily;
  String? value;

  Setting({
    this.sNo,
    this.title,
    this.widgetTypeId,
    this.iconCodePoint,
    this.iconFontFamily,
    this.value,
  });

  factory Setting.fromJson(Map<String, dynamic> json) => Setting(
    sNo: json["sNo"],
    title: json["title"],
    widgetTypeId: json["widgetTypeId"],
    iconCodePoint: json["iconCodePoint"],
    iconFontFamily: json["iconFontFamily"],
    value: json["value"],
  );

  Map<String, dynamic> toJson() => {
    "sNo": sNo,
    "title": title,
    "widgetTypeId": widgetTypeId,
    "iconCodePoint": iconCodePoint,
    "iconFontFamily": iconFontFamily,
    "value": value,
  };
}

