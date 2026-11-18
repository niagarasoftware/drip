
class EcModel{
  double sNo;
  String name;
  int controllerId;
  int ecControllerId;

  EcModel({
    required this.sNo,
    required this.name,
    this.controllerId = 0,
    this.ecControllerId = 0,
  });

  factory EcModel.fromJson(dynamic data){
    return EcModel(
        sNo: data['sNo'],
        name: data['name'],
        controllerId: data['controllerId'] ?? 0,
        ecControllerId: data['ecControllerId'] ?? 0
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'sNo' : sNo,
      'name' : name,
      'controllerId' : controllerId,
      'ecControllerId' : ecControllerId,
    };
  }

}