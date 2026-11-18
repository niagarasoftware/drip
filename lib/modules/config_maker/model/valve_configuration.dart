import 'device_object_model.dart';

class ValveConfigModel{
  DeviceObjectModel commonDetails;
  List<double> inputPressure;
  List<double> lateralPressure;

  ValveConfigModel({
    required this.commonDetails,
    required this.inputPressure,
    required this.lateralPressure,
  });

  factory ValveConfigModel.fromJson(dynamic data){
    DeviceObjectModel deviceObjectModel = DeviceObjectModel.fromJson(data);
    return ValveConfigModel(
        commonDetails: deviceObjectModel,
        inputPressure: data['inputPressure'] != null ? (data['inputPressure'] as List<dynamic>).map((sNo) => sNo as double).toList() : [],
        lateralPressure: data['lateralPressure'] != null ? (data['lateralPressure'] as List<dynamic>).map((sNo) => sNo as double).toList() : []
    );
  }

  Map<String, dynamic> toJson(){
    var commonInfo = commonDetails.toJson();
    commonInfo.addAll({
      'inputPressure' : inputPressure,
      'lateralPressure' : lateralPressure,
    });
    return commonInfo;
  }

  void updateObjectIdIfDeletedInProductLimit(List<double> objectIdToBeDeleted){
    inputPressure = inputPressure.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
    lateralPressure = lateralPressure.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
  }

  bool valveModelParameterIsEmpty(){
    if(inputPressure.isEmpty && lateralPressure.isEmpty){
      return true;
    }
    return false;
  }
}