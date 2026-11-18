// import 'dart:convert';
//
// Filterbackwash filterbackwashFromJson(String str) =>
//     Filterbackwash.fromJson(json.decode(str));
//
// String filterbackwashToJson(Filterbackwash data) => json.encode(data.toJson());
//
// class Filterbackwash {
//   int? code;
//   String? message;
//   List<Datum>? data;
//   String? controllerReadStatus;
//
//   Filterbackwash({
//     this.code,
//     this.message,
//     this.data,
//     this.controllerReadStatus,
//   });
//
//   factory Filterbackwash.fromJson(Map<String, dynamic> json) {
//     // Check if the 'data' is a list or a map
//     print("runtimeType${json["data"].runtimeType}");
//     if (json["data"] is List) {
//       print("runtimeType list");
//       // Old format, where 'data' is a list
//       return Filterbackwash(
//         code: json["code"],
//         message: json["message"],
//         controllerReadStatus: json["controllerReadStatus"],
//         data: json["data"] == null
//             ? []
//             : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
//       );
//     } else if (json["data"] is Map) {
//       print("runtimeType map");
//       // New format, where 'data' contains a 'backwash' field (which is a list)
//       return Filterbackwash(
//         code: json["code"],
//         message: json["message"],
//         data: json["data"]["filterBackwashing"] == null
//             ? []
//             : List<Datum>.from(json["data"]["filterBackwashing"]!.map((x) => Datum.fromJson(x))),
//       );
//     } else {
//       throw Exception("Unexpected JSON format");
//     }
//   }
//
//   Map<String, dynamic> toJson() => {
//     "code": code,
//     "message": message,
//     "data": data == null
//         ? []
//         : List<dynamic>.from(data!.map((x) => x.toJson())),
//   };
// }
//
// class Filter {
//   int? sNo;
//   String? title;
//   int? widgetTypeId;
//   String? iconCodePoint;
//   String? iconFontFamily;
//   dynamic value;
//   bool? hidden;
//
//   Filter({
//     this.sNo,
//     this.title,
//     this.widgetTypeId,
//     this.iconCodePoint,
//     this.iconFontFamily,
//     this.value,
//     this.hidden,
//   });
//
//   factory Filter.fromJson(Map<String, dynamic> json) => Filter(
//     sNo: json["sNo"],
//     title: json["title"],
//     widgetTypeId: json["widgetTypeId"],
//     iconCodePoint: json["iconCodePoint"],
//     iconFontFamily: json["iconFontFamily"],
//     value: json["value"],
//     hidden: json["hidden"],
//   );
//
//   Map<String, dynamic> toJson() => {
//     "sNo": sNo,
//     "title": title,
//     "widgetTypeId": widgetTypeId,
//     "iconCodePoint": iconCodePoint,
//     "iconFontFamily": iconFontFamily,
//     "value": value,
//     "hidden": hidden,
//   };
// }
//
// class Datum {
//   int? sNo;
//   String? id;
//    String? name;
//   String? location;
//   List<Filter>? filter;
//   String? value;
//
//   Datum({
//     this.sNo,
//     this.id,
//      this.name,
//     this.location,
//     this.filter,
//     this.value,
//   });
//
//   factory Datum.fromJson(Map<String, dynamic> json) => Datum(
//     sNo: json["sNo"],
//     id: json["objectId"],
//      name: json["name"],
//     location: json["location"],
//     filter: json["filter"] == null
//         ? []
//         : List<Filter>.from(json["filter"]!.map((x) => Filter.fromJson(x))),
//     value: json["value"],
//   );
//
//   Map<String, dynamic> toJson() => {
//     "sNo": sNo,
//     "id": id,
//      "name": name,
//     "location": location,
//     "filter": filter == null
//         ? []
//         : List<dynamic>.from(filter!.map((x) => x.toJson())),
//     "value": value,
//   };
// }
import 'dart:convert';

Filterbackwash filterbackwashFromJson(String str) => Filterbackwash.fromJson(json.decode(str));

String filterbackwashToJson(Filterbackwash data) => json.encode(data.toJson());

class Filterbackwash {
  int? code;
  String? message;
  Data? data;

  Filterbackwash({
    this.code,
    this.message,
    this.data,
  });

  factory Filterbackwash.fromJson(Map<String, dynamic> json) {
    return Filterbackwash(
     code: json["code"],
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );
  }

  Map<String, dynamic> toJson() => {
    "code": code,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  List<FilterBackwashing>? filterBackwashing;
  String? controllerReadStatus;
  List<String>? whileBackwash;

  Data({
    this.filterBackwashing,
    this.controllerReadStatus,
    this.whileBackwash,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
    filterBackwashing: json["filterBackwashing"] == null ? [] : List<FilterBackwashing>.from(json["filterBackwashing"]!.map((x) => FilterBackwashing.fromJson(x))),
    controllerReadStatus: json["controllerReadStatus"],
    whileBackwash: json["whileBackwash"] == null ? [] : List<String>.from(json["whileBackwash"]!.map((x) => x)),
  );
  }

  Map<String, dynamic> toJson() => {
    "filterBackwashing": filterBackwashing == null ? [] : List<dynamic>.from(filterBackwashing!.map((x) => x.toJson())),
    "controllerReadStatus": controllerReadStatus,
    "whileBackwash": whileBackwash == null ? [] : List<dynamic>.from(whileBackwash!.map((x) => x)),
  };
}

class Filter {
  int? sNo;
  String? title;
  int? widgetTypeId;
  String? iconCodePoint;
  String? iconFontFamily;
  dynamic value;
  bool? hidden;

  Filter({
    this.sNo,
    this.title,
    this.widgetTypeId,
    this.iconCodePoint,
    this.iconFontFamily,
    this.value,
    this.hidden,
  });

  factory Filter.fromJson(Map<String, dynamic> json) {
    return Filter(
    sNo: json["sNo"],
    title: json["title"],
    widgetTypeId: json["widgetTypeId"],
    iconCodePoint: json["iconCodePoint"],
    iconFontFamily: json["iconFontFamily"],
    value: json["value"],
    hidden: json["hidden"],
  );
  }

  Map<String, dynamic> toJson() => {
    "sNo": sNo,
    "title": title,
    "widgetTypeId": widgetTypeId,
    "iconCodePoint": iconCodePoint,
    "iconFontFamily": iconFontFamily,
    "value": value,
    "hidden": hidden,
  };
}

class FilterBackwashing {
  int? objectId;
  double? sNo;
  String? name;
  String? objectName;
  List<Filter>? filter;

  FilterBackwashing({
    this.objectId,
    this.sNo,
    this.name,
    this.objectName,
    this.filter,
   });

  factory FilterBackwashing.fromJson(Map<String, dynamic> json) {
    return FilterBackwashing(
    objectId: json["objectId"],
    sNo: json["sNo"],
    name: json["name"],
    objectName: json["objectName"],
    filter: json["filter"] == null ? [] : List<Filter>.from(json["filter"]!.map((x) => Filter.fromJson(x))),
   );
  }

  Map<String, dynamic> toJson() => {
    "objectId": objectId,
    "sNo": sNo,
    "name": name,
    "objectName": objectName,
    "filter": filter == null ? [] : List<dynamic>.from(filter!.map((x) => x.toJson())),
   };
}
