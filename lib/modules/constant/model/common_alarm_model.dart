import 'package:oro_drip_irrigation/utils/constants.dart';
import 'alarm_in_constant_model.dart';

class CommonAlarmModel {
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  final double location;
  List<AlarmInConstantModel> alarmList;

  CommonAlarmModel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.location,
    required this.alarmList,
  });

  factory CommonAlarmModel.fromJson({
    required dynamic objectData,
    required List<dynamic> defaultSetting,
    required List<dynamic> globalAlarm,
    required Map<String, dynamic>? oldSetting,
    required Map<String, dynamic> userData,
  }) {
    bool isEcoGem = AppConstants.ecoGemModelList.contains(userData['modelId']);
    bool isOmsGem = AppConstants.omsGemList.contains(userData['modelId']);

    List<dynamic> savedAlarms = [];
    if (oldSetting != null) {
      if (oldSetting.containsKey('alarm') && oldSetting['alarm'] is List) {
        savedAlarms = oldSetting['alarm'] as List<dynamic>;
      } else if (oldSetting.containsKey('common') && oldSetting['common'] is List) {
        savedAlarms = oldSetting['common'] as List<dynamic>;
      } else if (oldSetting.containsKey('normal') && oldSetting['normal'] is List) {
        savedAlarms = oldSetting['normal'] as List<dynamic>;
      }
    }

    return CommonAlarmModel(
      objectId: objectData['objectId'],
      sNo: (objectData['sNo'] is num)
          ? (objectData['sNo'] as num).toDouble()
          : (double.tryParse(objectData['sNo'].toString()) ?? 0.0),
      name: objectData['name'] ?? '',
      objectName: objectData['objectName'] ?? '',
      location: (objectData['location'] is num)
          ? (objectData['location'] as num).toDouble()
          : (double.tryParse(objectData['location'].toString()) ?? 0.0),
      alarmList: globalAlarm
          .where((setting) => (isEcoGem
              ? setting['ecoGemDisplay']
              : isOmsGem
                  ? setting['omsGemDisplay']
                  : setting['gemDisplay']))
          .map((alarm) {
        List<dynamic> oldAlarmSetting = savedAlarms
            .where((item) => item['sNo'] == alarm['sNo'])
            .toList();
        return AlarmInConstantModel.fromJson(
          objectData: alarm,
          defaultSetting: defaultSetting,
          oldSetting: oldAlarmSetting,
        );
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'sNo': sNo,
      'name': name,
      'objectName': objectName,
      'location': location,
      'alarm': alarmList.map((alarm) => alarm.toJson()).toList(),
      'common': alarmList.map((alarm) => alarm.toJson()).toList(),
    };
  }
}
