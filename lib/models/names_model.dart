
import 'dart:convert';

import '../modules/config_maker/model/device_object_model.dart';
import '../modules/config_maker/model/fertigation_model.dart';
import '../modules/config_maker/model/filtration_model.dart';
import '../modules/config_maker/model/irrigation_line_model.dart';
import '../modules/config_maker/model/moisture_model.dart';
import '../modules/config_maker/model/pump_model.dart';
import '../modules/config_maker/model/source_model.dart';

NamesConfigModel namesConfigModelFromJson(String str) => NamesConfigModel.fromJson(json.decode(str));

String namesConfigModelToJson(NamesConfigModel data) => json.encode(data.toJson());

class NamesConfigModel {
  List<DeviceObjectModel>? configObject;
  List<SourceModel>? waterSource;
  List<PumpModel>? pump;
  List<FiltrationModel>? filterSite;
  List<FertilizationModel>? fertilizerSite;
  List<MoistureModel>? moistureSensor;
  List<IrrigationLineModel>? irrigationLine;

  NamesConfigModel({
    this.configObject,
    this.waterSource,
    this.pump,
    this.filterSite,
    this.fertilizerSite,
    this.moistureSensor,
    this.irrigationLine,
  });

  factory NamesConfigModel.fromJson(Map<String, dynamic> json) => NamesConfigModel(
    configObject: json["configObject"] == null ? [] : List<DeviceObjectModel>.from(json["configObject"]!.map((x) => DeviceObjectModel.fromJson(x))),
    waterSource: json["waterSource"] == null ? [] : List<SourceModel>.from(json["waterSource"]!.map((x) => SourceModel.fromJson(x))),
    pump: json["pump"] == null ? [] : List<PumpModel>.from(json["pump"]!.map((x) => PumpModel.fromJson(x))),
    filterSite: json["filterSite"] == null ? [] : List<FiltrationModel>.from(json["filterSite"]!.map((x) => FiltrationModel.fromJson(x))),
    fertilizerSite: json["fertilizerSite"] == null ? [] : List<FertilizationModel>.from(json["fertilizerSite"]!.map((x) => FertilizationModel.fromJson(x))),
    moistureSensor: json["moistureSensor"] == null ? [] : List<MoistureModel>.from(json["moistureSensor"]!.map((x) => MoistureModel.fromJson(x))),
    irrigationLine: json["irrigationLine"] == null ? [] : List<IrrigationLineModel>.from(json["irrigationLine"]!.map((x) => IrrigationLineModel.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "configObject": configObject == null ? [] : List<dynamic>.from(configObject!.map((x) => x.toJson())),
    "waterSource": waterSource == null ? [] : List<dynamic>.from(waterSource!.map((x) => x.toJson())),
    "pump": pump == null ? [] : List<dynamic>.from(pump!.map((x) => x.toJson())),
    "filterSite": filterSite == null ? [] : List<dynamic>.from(filterSite!.map((x) => x.toJson())),
    "fertilizerSite": fertilizerSite == null ? [] : List<dynamic>.from(fertilizerSite!.map((x) => x.toJson())),
    "moistureSensor": moistureSensor == null ? [] : List<dynamic>.from(moistureSensor!.map((x) => x.toJson())),
    "irrigationLine": irrigationLine == null ? [] : List<dynamic>.from(irrigationLine!.map((x) => x.toJson())),
  };

  String getNameBySNo(double sNo) {
     for (var obj in configObject ?? []) {
       if (obj.sNo == sNo) {
        return obj.name ?? "Not found";
      }
    }
    return "Not found";
  }
}


