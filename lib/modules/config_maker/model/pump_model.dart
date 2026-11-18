import 'package:oro_drip_irrigation/modules/config_maker/model/irrigation_line_model.dart';
import 'device_object_model.dart';

class PumpModel{
  DeviceObjectModel commonDetails;
  double lowerLevel;
  double upperLevel;
  double pressureIn;
  double pressureOut;
  double waterMeter;
  double topTankFloat;
  double bottomTankFloat;
  double topSumpFloat;
  double bottomSumpFloat;
  int pumpType;
  bool automateFloatSelection;

  PumpModel({
    required this.commonDetails,
    this.lowerLevel = 0.0,
    this.upperLevel = 0.0,
    this.pressureIn = 0.0,
    this.pressureOut = 0.0,
    this.waterMeter = 0.0,
    this.topTankFloat = 0.0,
    this.bottomTankFloat = 0.0,
    this.topSumpFloat = 0.0,
    this.bottomSumpFloat = 0.0,
    this.pumpType = 1,
    this.automateFloatSelection = false,
  });

  void updateObjectIdIfDeletedInProductLimit(List<double> objectIdToBeDeleted){
    lowerLevel = objectIdToBeDeleted.contains(lowerLevel) ? 0.0 : lowerLevel;
    upperLevel = objectIdToBeDeleted.contains(upperLevel) ? 0.0 : upperLevel;
    waterMeter = objectIdToBeDeleted.contains(waterMeter) ? 0.0 : waterMeter;
    pressureIn = objectIdToBeDeleted.contains(pressureIn) ? 0.0 : pressureIn;
    pressureOut = objectIdToBeDeleted.contains(pressureOut) ? 0.0 : pressureOut;
    topTankFloat = objectIdToBeDeleted.contains(topTankFloat) ? 0.0 : topTankFloat;
    bottomTankFloat = objectIdToBeDeleted.contains(bottomTankFloat) ? 0.0 : bottomTankFloat;
    topSumpFloat = objectIdToBeDeleted.contains(topSumpFloat) ? 0.0 : topSumpFloat;
    bottomSumpFloat = objectIdToBeDeleted.contains(bottomSumpFloat) ? 0.0 : bottomSumpFloat;
  }

  factory PumpModel.fromJson(dynamic data){
    DeviceObjectModel deviceObjectModel = DeviceObjectModel.fromJson(data);
    return PumpModel(
        commonDetails: deviceObjectModel,
        lowerLevel: intOrDoubleValidate(data['level'] ?? data['lowerLevel']),
        upperLevel: intOrDoubleValidate(data['upperLevel'] ?? 0.0),
        pressureIn: intOrDoubleValidate(data['pressureIn']),
        pressureOut: intOrDoubleValidate(data['pressureOut']),
        waterMeter: intOrDoubleValidate(data['waterMeter']),
        topTankFloat: intOrDoubleValidate(data['topTankFloat'] ?? 0.0),
        bottomTankFloat: intOrDoubleValidate(data['bottomTankFloat'] ?? 0.0),
        topSumpFloat: intOrDoubleValidate(data['topSumpFloat'] ?? 0.0),
        bottomSumpFloat: intOrDoubleValidate(data['bottomSumpFloat'] ?? 0.0),
        pumpType: data['pumpType'],
        automateFloatSelection: data['automateFloatSelection'] ?? false
    );
  }

  Map<String, dynamic> toJson(){
    var commonInfo = commonDetails.toJson();
    commonInfo.addAll({
      'level' : lowerLevel,
      'upperLevel' : upperLevel,
      'pressureIn' : pressureIn,
      'pressureOut' : pressureOut,
      'waterMeter' : waterMeter,
      'topTankFloat' : topTankFloat,
      'bottomTankFloat' : bottomTankFloat,
      'topSumpFloat' : topSumpFloat,
      'bottomSumpFloat' : bottomSumpFloat,
      'pumpType' : pumpType,
      'automateFloatSelection' : automateFloatSelection,
    });
    return commonInfo;
  }

}