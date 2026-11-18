class EcPhSettingModel{
  final int objectId;
  final double sNo;
  final String name;

  EcPhSettingModel({
    required this.objectId,
    required this.sNo,
    required this.name,
  });

  factory EcPhSettingModel.fromJson(data){
    return EcPhSettingModel(
        objectId: data['objectId'],
        sNo: data['sNo'],
        name: data['name'],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'objectId' : objectId,
      'sNo' : sNo,
      'name' : name,
    };
  }
}