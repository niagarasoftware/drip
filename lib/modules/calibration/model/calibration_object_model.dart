class CalibrationObjectModel {
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  String getData1;
  String getData2;
  String getData3;
  String calibrationFactor;
  String maximumValue;


  CalibrationObjectModel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.getData1,
    required this.getData2,
    required this.getData3,
    required this.calibrationFactor,
    required this.maximumValue,
  });

  factory CalibrationObjectModel.fromJson(Map<String, dynamic> data){
    return CalibrationObjectModel(
        objectId: data['objectId'],
        sNo: data['sNo'],
        name: data['name'],
        objectName: data['objectName'],
        getData1: data['getData1'],
        getData2: data['getData2'],
        getData3: data['getData3'],
        calibrationFactor: data['calibrationFactor'],
        maximumValue: data['maximumValue']
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'objectId' : objectId,
      'sNo' : sNo,
      'name' : name,
      'objectName' : objectName,
      'getData1' : getData1,
      'getData2' : getData2,
      'getData3' : getData3,
      'calibrationFactor' : calibrationFactor,
      'maximumValue' : maximumValue,
    };
  }
}