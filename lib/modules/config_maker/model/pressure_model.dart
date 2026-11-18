import 'device_object_model.dart';

class PressureModel{
  DeviceObjectModel commonDetails;
  List<double> mainValve;

  PressureModel({
    required this.commonDetails,
    required this.mainValve,
  });

  factory PressureModel.fromJson(dynamic data){
    DeviceObjectModel deviceObjectModel = DeviceObjectModel.fromJson(data);
    return PressureModel(
        commonDetails: deviceObjectModel,
        mainValve: data['mainValve'] != null ? (data['mainValve'] as List<dynamic>).map((sNo) => sNo as double).toList() : []
    );
  }

  Map<String, dynamic> toJson(){
    var commonInfo = commonDetails.toJson();
    commonInfo.addAll({
      'mainValve' : mainValve,
    });
    return commonInfo;
  }

  void updateObjectIdIfDeletedInProductLimit(List<double> objectIdToBeDeleted){
    mainValve = mainValve.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
  }

  bool isPressureModelParameterIsEmpty(){
    if(mainValve.isEmpty){
      return true;
    }
    return false;
  }
}