
import 'package:oro_drip_irrigation/utils/constants.dart';

import 'alarm_in_constant_model.dart';

class NormalCriticalAlarmModel{
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  final double location;
  List<AlarmInConstantModel> normal;
  List<AlarmInConstantModel> critical;

  NormalCriticalAlarmModel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.location,
    required this.normal,
    required this.critical,
  });

  factory NormalCriticalAlarmModel.fromJson({
    required objectData,
    required List<dynamic> defaultSetting,
    required List<dynamic> globalAlarm,
    required Map<String, dynamic>? oldSetting,
    required Map<String, dynamic> userData,
  }){
    print("userData['modelId'] : ${userData['modelId']}");
    bool isEcoGem = AppConstants.ecoGemModelList.contains(userData['modelId']);
    bool isOmsGem = AppConstants.omsGemList.contains(userData['modelId']);
    print('isEcoGem : $isEcoGem');
    print('isOmsGem : $isOmsGem');
    return NormalCriticalAlarmModel(
        objectId: objectData['objectId'],
        sNo: objectData['sNo'],
        name: objectData['name'],
        objectName: objectData['objectName'],
        location: objectData['location'],
        normal: globalAlarm.where((setting) => (
            isEcoGem ? setting['ecoGemDisplay']
                : isOmsGem ?  setting['omsGemDisplay']
                : setting['gemDisplay'])).map((alarm){
          return AlarmInConstantModel.fromJson(
              objectData: alarm,
              defaultSetting: defaultSetting,
              oldSetting: oldSetting == null ? [] : (oldSetting['normal'] as List<dynamic>).where((item) => item['sNo'] == alarm['sNo']).toList()
          );
        }).toList(),
        critical: globalAlarm.where((setting) => (
            isEcoGem ?  setting['ecoGemDisplay']
                : isOmsGem ?  setting['omsGemDisplay']
                : setting['gemDisplay'])).map((alarm){
          return AlarmInConstantModel.fromJson(
              objectData: alarm,
              defaultSetting: defaultSetting,
              oldSetting: oldSetting == null ? [] : (oldSetting['critical'] as List<dynamic>).where((item) => item['sNo'] == alarm['sNo']).toList()
          );
        }).toList(),
      );
  }

  Map<String, dynamic> toJson(){
    return {
      'objectId' : objectId,
      'sNo' : sNo,
      'name' : name,
      'objectName' : objectName,
      'location' : location,
      'normal' : normal.map((alarm) {
        return alarm.toJson();
      }).toList(),
      'critical' : critical.map((alarm) {
        return alarm.toJson();
      }).toList(),
    };
  }
}