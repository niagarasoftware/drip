import 'device_object_model.dart';

class ChannelConfigModel{
  DeviceObjectModel commonDetails;
  double dosingMeter;
  List<double> outletTankValve;

  ChannelConfigModel({
    required this.commonDetails,
    this.dosingMeter = 0.0,
    required this.outletTankValve,
  });

  factory ChannelConfigModel.fromJson(dynamic data){
    DeviceObjectModel deviceObjectModel = DeviceObjectModel.fromJson(data);
    return ChannelConfigModel(
        commonDetails: deviceObjectModel,
        dosingMeter: data['dosingMeter'] ?? 0.0,
        outletTankValve: data['outletTankValve'] != null
            ? (data['outletTankValve'] as List<dynamic>).map((sNo) => (sNo as num).toDouble()).toList() 
            : [],
    );
  }

  Map<String, dynamic> toJson(){
    var commonInfo = commonDetails.toJson();
    commonInfo.addAll({
      'dosingMeter' : dosingMeter,
      'outletTankValve' : outletTankValve,
    });
    return commonInfo;
  }

  void updateObjectIdIfDeletedInProductLimit(List<double> objectIdToBeDeleted){
    dosingMeter = objectIdToBeDeleted.contains(dosingMeter) ? 0.0 : dosingMeter;
    outletTankValve = outletTankValve.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
  }
}