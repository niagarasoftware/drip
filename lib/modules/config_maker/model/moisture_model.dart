import 'device_object_model.dart';

class MoistureModel{
  DeviceObjectModel commonDetails;
  List<double> valves;
  List<double> soilTemperature;

  MoistureModel({
    required this.commonDetails,
    required this.valves,
    required this.soilTemperature,
  });

  factory MoistureModel.fromJson(dynamic data){
    DeviceObjectModel deviceObjectModel = DeviceObjectModel.fromJson(data);
    return MoistureModel(
        commonDetails: deviceObjectModel,
        valves: (data['valves'] as List<dynamic>).map((sNo) => sNo as double).toList(),
        soilTemperature: data['soilTemperature'] != null ? (data['soilTemperature'] as List<dynamic>).map((sNo) => sNo as double).toList() : []
    );
  }

  Map<String, dynamic> toJson(){
    var commonInfo = commonDetails.toJson();
    commonInfo.addAll({
      'valves' : valves,
      'soilTemperature' : soilTemperature,
    });
    return commonInfo;
  }

  void updateObjectIdIfDeletedInProductLimit(List<double> objectIdToBeDeleted){
    valves = valves.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
    soilTemperature = soilTemperature.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
  }

  bool isMoistureModelParameterIsEmpty(){
    if(valves.isEmpty && soilTemperature.isEmpty){
      return true;
    }
    return false;
  }
}