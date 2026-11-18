import 'dart:convert';

HiddenMenu hiddenMenuFromJson(String str) => HiddenMenu.fromJson(json.decode(str));

String hiddenMenuToJson(HiddenMenu data) => json.encode(data.toJson());

class HiddenMenu {
  int? code;
  String? message;
  List<Datum>? data;

  HiddenMenu({
    this.code,
    this.message,
    this.data,
  });

  factory HiddenMenu.fromJson(Map<String, dynamic> json) {
    var hiddenMenu = HiddenMenu(
      code: json["code"],
      message: json["message"],
      data: json["data"] == null
          ? []
          : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    );

    hiddenMenu.sortData();

    return hiddenMenu;
  }

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };

  void sortData() {
    List<int> customOrder = [80, 78, 72, 79, 127, 75, 74, 70, 73, 69, 67, 68, 66, 71];

    data?.sort((a, b) {
      int indexA = customOrder.indexOf(a.dealerDefinitionId ?? -1);
      int indexB = customOrder.indexOf(b.dealerDefinitionId ?? -1);

      if (indexA == -1 && indexB == -1) {
        return (a.dealerDefinitionId ?? 0).compareTo(b.dealerDefinitionId ?? 0);
      } else if (indexA == -1) {
        return 1;
      } else if (indexB == -1) {
        return -1;
      } else {
        return indexA.compareTo(indexB);
      }
    });
  }

}

class Datum {
  int? dealerDefinitionId;
  String? parameter;
  String? value;
  bool controllerReadStatus;

  Datum({
    this.dealerDefinitionId,
    this.parameter,
    this.value,
    required this.controllerReadStatus,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    dealerDefinitionId: json["dealerDefinitionId"],
    controllerReadStatus: json["controllerReadStatus"] == "1",
    parameter: json["parameter"],
    value: json["value"],
  );

  Map<String, dynamic> toJson() => {
    "dealerDefinitionId": dealerDefinitionId,
    "parameter": parameter,
    "value": value,
    "controllerReadStatus": controllerReadStatus,
  };
}
