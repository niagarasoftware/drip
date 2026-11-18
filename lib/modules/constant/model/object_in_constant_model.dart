import 'package:oro_drip_irrigation/modules/constant/model/constant_setting_model.dart';

class ObjectInConstantModel{
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  final double? location;
  final int? controllerId;
  final int? connectionNo;
  List<ConstantSettingModel> setting = [];

  ObjectInConstantModel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.location,
    required this.controllerId,
    required this.connectionNo,
    required this.setting,
  });

  factory ObjectInConstantModel.fromJson({
    required objectData,
    required List<dynamic> defaultSetting,
    required List<dynamic> oldSetting
  }){
    print("objectData['location']: ${objectData['location']}");
    return ObjectInConstantModel(
        objectId: objectData['objectId'],
        sNo: objectData['sNo'],
        name: objectData['name'],
        objectName: objectData['objectName'],
        location: objectData['location'] == 0 ? 0.0 : objectData['location'],
        controllerId: objectData['controllerId'],
        connectionNo: objectData['connectionNo'],
        setting : defaultSetting.map((setting){
          List<dynamic> oldData = oldSetting.where((oldSetting) => oldSetting['sNo'] == setting['sNo']).toList();
          return ConstantSettingModel.fromJson(setting, oldData.firstOrNull);
        }).toList()
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'objectId' : objectId,
      'sNo' : sNo,
      'name' : name,
      'objectName' : objectName,
      'location' : location,
      'controllerId' : controllerId,
      'connectionNo' : connectionNo,
      'setting' : setting.map((setting) => setting.toJson()).toList()
    };
  }
}