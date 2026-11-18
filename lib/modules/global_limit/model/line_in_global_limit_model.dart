import 'package:oro_drip_irrigation/modules/global_limit/model/valve_with_central_local_channel_model.dart';

class LineInGlobalLimitModel {
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  List<ValveWithCentralLocalChannelModel> valve;
  final int centralCount;
  final int localCount;

  LineInGlobalLimitModel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.valve,
    required this.centralCount,
    required this.localCount,
  });

  factory LineInGlobalLimitModel.fromJson(data){
    int centralCount = 0;
    int localCount = 0;
    String name = data['name'];
    return LineInGlobalLimitModel(
        objectId: data['objectId'],
        sNo: data['sNo'],
        name: data['name'],
        objectName: data['objectName'],
        valve: (data['valve'] as List<dynamic>).map((valve){
          if(centralCount == 0 && localCount == 0){
            for(var key in valve.keys){
              if(key.contains('central')){
                if((valve[key] as Map<String, dynamic>).isNotEmpty){
                  centralCount++;
                }
              }else if(key.contains('local')){
                if((valve[key] as Map<String, dynamic>).isNotEmpty){
                  localCount++;
                }
              }
            }
          }
          return ValveWithCentralLocalChannelModel.fromJson(valve);
        }).toList(),
      centralCount: centralCount,
      localCount: localCount,
    );
  }

  Map<String, dynamic> toJson(){
    return {
      "objectId" : objectId,
      "sNo" : sNo,
      "name" : name,
      "objectName" : objectName,
      "valve" : valve.map((valve){
        return valve.toJson();
      }).toList(),
    };
  }
}