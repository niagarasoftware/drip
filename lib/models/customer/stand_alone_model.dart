import 'package:oro_drip_irrigation/models/customer/site_model.dart';

class StandAloneModel
{
  bool startTogether;
  String time, flow;
  int method;
  final List<Selection> selection;
  final List<SequenceModel> sequence;

  StandAloneModel({
    required this.startTogether,
    required this.time,
    required this.flow,
    required this.method,
    required this.selection,
    required this.sequence,
  });

  factory StandAloneModel.fromJson(Map<String, dynamic> json) {
    return StandAloneModel(
      startTogether: json['startTogether'] as bool,
      time: json['duration'] as String,
      flow: json['flow'] as String,
      method: json['method'] as int,
      selection: (json['selection'] as List<dynamic>?)
          ?.map((e) => Selection.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      sequence: (json['sequence'] as List<dynamic>?)
          ?.map((e) => SequenceModel.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class Selection {
  final dynamic sNo;
  bool selected;

  Selection({
    required this.sNo,
    this.selected=true,
  });

  factory Selection.fromJson(Map<String, dynamic> json) {
    return Selection(
      sNo: json['sNo'],
      //selected: json['selected'],
    );
  }
}

class SequenceModel {
  String sNo;
  String id;
  String name;
  bool selected;
  List<dynamic> selectedGroup;
  bool modified;
  String location;
  List<ValveSA> valve;

  SequenceModel({
    required this.sNo,
    required this.id,
    required this.name,
    required this.selected,
    required this.selectedGroup,
    required this.modified,
    required this.location,
    required this.valve,
  });

  factory SequenceModel.fromMap(Map<String, dynamic> json) => SequenceModel(
    sNo: json["sNo"],
    id: json["id"],
    name: json["name"],
    selected: json["selected"],
    selectedGroup: List<dynamic>.from(json["selectedGroup"]),
    modified: json["modified"],
    location: json["location"],
    valve: (json['valve'] as List).map((v) => ValveSA.fromJson(v))
        .toList(),
  );
}