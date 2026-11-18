import 'device_object_model.dart';
import 'irrigation_line_model.dart';

class FertilizationModel{
  DeviceObjectModel commonDetails;
  int siteMode;
  List<Injector> channel;
  List<double> boosterPump;
  List<double> agitator;
  List<double> selector;
  List<double> ec;
  List<double> ph;

  FertilizationModel({
    required this.commonDetails,
    this.siteMode = 1,
    required this.channel,
    required this.boosterPump,
    required this.agitator,
    required this.selector,
    required this.ec,
    required this.ph,
  });

  void updateObjectIdIfDeletedInProductLimit(List<double> objectIdToBeDeleted){
    ec = ec.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
    ph = ph.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
    selector = selector.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
    agitator = agitator.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
    boosterPump = boosterPump.where((objectId) => !objectIdToBeDeleted.contains(objectId)).toList();
    channel = channel.where((objectId) => !objectIdToBeDeleted.contains(objectId.sNo)).toList();
    for(var ch in channel){
      ch.updateObjectIdIfDeletedInProductLimit(objectIdToBeDeleted);
    }
  }

  factory FertilizationModel.fromJson(data){
    DeviceObjectModel deviceObjectModel = DeviceObjectModel.fromJson(data);
    print('from json in fertilization');
    return FertilizationModel(
        commonDetails: deviceObjectModel,
      siteMode: data['siteMode'],
        channel: (data['channel'] as List<dynamic>).map((channel) => Injector.fromJson(channel)).toList(),
        boosterPump: (data['boosterPump'] as List<dynamic>).map((sNo) => sNo as double).toList(),
        agitator: (data['agitator'] as List<dynamic>).map((sNo) => sNo as double).toList(),
        selector: (data['selector'] as List<dynamic>).map((sNo) => sNo as double).toList(),
        ec: (data['ec'] as List<dynamic>).map((sNo) => sNo as double).toList(),
        ph: (data['ph'] as List<dynamic>).map((sNo) => sNo as double).toList(),
    );
  }

  Map<String, dynamic> toJson(){
    var commonInfo = commonDetails.toJson();
    commonInfo.addAll({
      'siteMode' : siteMode,
      'channel' : channel.map((injector) => injector.toJson()).toList(),
      'boosterPump' : boosterPump,
      'agitator' : agitator,
      'selector' : selector,
      'ec' : ec,
      'ph' : ph,
    });
    return commonInfo;
  }
}

class Injector{
  final double sNo;
  double level;
  Injector({
    required this.sNo,
    this.level = 0.0,
  });

  factory Injector.fromJson(data){
    return Injector(
        sNo: data['sNo'],
      level: intOrDoubleValidate(data['level'])
    );
  }

  void updateObjectIdIfDeletedInProductLimit(List<double> objectIdToBeDeleted){
    level = objectIdToBeDeleted.contains(level) ? 0.0 : level;
  }


  Map<String, dynamic> toJson(){
    return {
      'sNo' : sNo,
      'level' : level
    };
  }
}
