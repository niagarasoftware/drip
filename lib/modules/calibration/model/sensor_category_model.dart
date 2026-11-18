
import 'calibration_object_model.dart';

class SensorCategoryModel {
  final int objectTypeId;
  final String object;
  final String calibrationCount;
  List<CalibrationObjectModel> calibrationObject;
  SensorCategoryModel({
    required this.objectTypeId,
    required this.object,
    required this.calibrationCount,
    required this.calibrationObject,
  });

  factory SensorCategoryModel.fromJson(data){
    return SensorCategoryModel(
        objectTypeId: data['objectTypeId'],
        object: data['object'],
        calibrationCount: data['calibrationCount'] ?? '',
        calibrationObject: (data['objectList'] as List<dynamic>).map((element){
          return CalibrationObjectModel.fromJson(element);
        }).toList()
    );
  }

  Map<String, dynamic> toJson(){
    return {
      "objectTypeId" : objectTypeId,
      "object" : object,
      "calibrationCount" : calibrationCount,
      "objectList" : calibrationObject.map((object) => object.toJson()).toList()
    };
  }
}
