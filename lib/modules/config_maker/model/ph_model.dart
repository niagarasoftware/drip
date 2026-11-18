
class PhModel{
  double sNo;
  String name;
  int phControllerId;
  int controllerId;

  PhModel({
    required this.sNo,
    required this.name,
    this.controllerId = 0,
    this.phControllerId = 0,
  });

  factory PhModel.fromJson(dynamic data){
    return PhModel(
        sNo: data['sNo'],
        name: data['name'],
        controllerId: data['controllerId'] ?? 0,
        phControllerId: data['phControllerId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'sNo' : sNo,
      'name' : name,
      'controllerId' : controllerId,
      'phControllerId' : phControllerId,
    };
  }
}