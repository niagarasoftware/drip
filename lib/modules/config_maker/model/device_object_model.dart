
import '../../../utils/constants.dart';

class DeviceObjectModel {
  final int objectId;
  double? sNo;
  String? name;
  String objectName;
  int? connectionNo;
  final String type;
  int? controllerId;
  String? count;
  int? connectedObject;
  List<dynamic> assignObject;
  int? siteMode;
  double? location;

  DeviceObjectModel({
    required this.objectId,
    this.sNo,
    this.name,
    this.connectionNo,
    required this.objectName,
    required this.type,
    this.controllerId,
    this.count,
    this.connectedObject,
    required this.assignObject,
    this.siteMode,
    this.location,
  });

  factory DeviceObjectModel.fromJson(Map<String, dynamic> data) {
    return DeviceObjectModel(
      objectId: data['objectId'],
      sNo: data['sNo'],
      name: data['name'],
      connectionNo: data['connectionNo'],
      objectName: data['objectName'],
      type: data['type'] ?? '',
      controllerId: data['controllerId'],
      count: data['count'],
      connectedObject: data['connectedObject'],
      assignObject: data['assignObject'] ?? [],
      siteMode: data['siteMode'],
      location: (data['location'] == 0 ? 0.0 : data['location']) ?? 0.00,
    );
  }

  Map<String, dynamic> toJson({dynamic data}) {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
      'connectionNo': connectionNo,
      'objectName': objectName,
      'type': type,
      'controllerId': controllerId,
      'count': count,
      'connectedObject': connectedObject,
      'assignObject': assignObject,
      'siteMode': siteMode,
      if(data != null)
        'location' : AppConstants.findLocation(data: data, objectSno: sNo!, key: 'sNo')
      else
        'location' : location
    };
  }
}