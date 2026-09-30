import 'device_object_model.dart';

class ChannelConfigModel{
  DeviceObjectModel commonDetails;
  double dosingMeter;
  List<double> source;

  ChannelConfigModel({
    required this.commonDetails,
    this.dosingMeter = 0.0,
    required this.source,
  });

  factory ChannelConfigModel.fromJson(dynamic data){
    DeviceObjectModel deviceObjectModel = DeviceObjectModel.fromJson(data);
    return ChannelConfigModel(
        commonDetails: deviceObjectModel,
        dosingMeter: data['dosingMeter'] ?? 0.0,
        source: data['source'] != null ? (data['source'] as List<dynamic>).map((sNo) => sNo as double).toList() : [],
    );
  }

  Map<String, dynamic> toJson(){
    var commonInfo = commonDetails.toJson();
    commonInfo.addAll({
      'dosingMeter' : dosingMeter,
      'source' : source,
    });
    return commonInfo;
  }

  void updateObjectIdIfDeletedInProductLimit(List<double> objectIdToBeDeleted){
    dosingMeter = objectIdToBeDeleted.contains(dosingMeter) ? 0.0 : dosingMeter;
    source = source.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
  }
}