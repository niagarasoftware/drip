import 'package:flutter/cupertino.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import 'alarm_in_constant_model.dart';
import 'constant_setting_model.dart';

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
    var rawModelId = userData['modelId'] ??
        userData['modelid'] ??
        (userData['masterData'] is Map
            ? (userData['masterData']['modelId'] ??
                userData['masterData']['modelid'])
            : null);
    int? modelId = rawModelId is int
        ? rawModelId
        : int.tryParse(rawModelId?.toString() ?? '');

    bool isGem = AppConstants.gemModelList.contains(modelId);
    bool isEcoGem = AppConstants.ecoGemModelList.contains(modelId);
    bool isOmsGem = AppConstants.omsGemList.contains(modelId);

    List<dynamic> savedAlarms = [];
    bool isFromNormalCritical = false;
    if (oldSetting != null) {
      if (oldSetting.containsKey('alarm') && oldSetting['alarm'] is List) {
        savedAlarms = oldSetting['alarm'] as List<dynamic>;
      } else if (oldSetting.containsKey('common') && oldSetting['common'] is List) {
        savedAlarms = oldSetting['common'] as List<dynamic>;
      } else if (oldSetting.containsKey('normal') && oldSetting['normal'] is List) {
        savedAlarms = oldSetting['normal'] as List<dynamic>;
        isFromNormalCritical = true;
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
          .where((setting) => (isGem
              ? (setting['gemDisplay'] ?? true)
              : isEcoGem
                  ? (setting['ecoGemDisplay'] ?? true)
                  : isOmsGem
                      ? (setting['omsGemDisplay'] ?? true)
                      : (setting['gemDisplay'] ?? true)))
          .map((alarm) {
        List<dynamic> oldAlarmSetting = savedAlarms
            .where((item) => item['sNo'] == alarm['sNo'])
            .toList();

        List<ConstantSettingModel> settings = defaultSetting.map((settingDef) {
          int sNo = settingDef['sNo'];
          String title = settingDef['title']?.toString() ?? '';
          String titleLower = title.toLowerCase();
          int widgetTypeId = settingDef['widgetTypeId'] ?? 1;
          dynamic defaultValue = settingDef['value'];

          dynamic resolvedValue;

          if (isFromNormalCritical) {
            // normalCriticalAlarm settings are:
            // 1: Scan Time, 2: Alarm On Status, 3: Reset After Irrigation,
            // 4: Auto Reset Duration, 5: Threshold Value, 6: Auto Reset
            // While commonAlarm setting 1 is On/Off!
            if (titleLower.contains('on/off') || (widgetTypeId == 2 && sNo == 1)) {
              var gVal = alarm['value'];
              if (gVal is bool) {
                resolvedValue = gVal;
              } else if (gVal == 1 || gVal == '1' || gVal == 'true') {
                resolvedValue = true;
              } else {
                resolvedValue = defaultValue == true;
              }
            } else {
              // Map from normalCriticalAlarm settings (sNo - 1)
              int normalSno = sNo - 1;
              dynamic normalOldVal;
              if (oldAlarmSetting.isNotEmpty && oldAlarmSetting[0]['setting'] is List) {
                var found = (oldAlarmSetting[0]['setting'] as List)
                    .where((s) => s['sNo'] == normalSno)
                    .firstOrNull;
                if (found != null) {
                  normalOldVal = found['value'];
                }
              }
              resolvedValue = _validateAndCastValue(widgetTypeId, normalOldVal, defaultValue);
            }
          } else {
            // Already commonAlarm format
            dynamic savedVal;
            if (oldAlarmSetting.isNotEmpty && oldAlarmSetting[0]['setting'] is List) {
              var found = (oldAlarmSetting[0]['setting'] as List)
                  .where((s) => s['sNo'] == sNo)
                  .firstOrNull;
              if (found != null) {
                savedVal = found['value'];
              }
            }

            // Special fallback for On/Off from globalAlarm if saved value is invalid or corrupted
            if (titleLower.contains('on/off') || (widgetTypeId == 2 && sNo == 1)) {
              if (savedVal is bool) {
                resolvedValue = savedVal;
              } else if (savedVal == 1 || savedVal == '1' || savedVal == 'true') {
                resolvedValue = true;
              } else if (savedVal == 0 || savedVal == '0' || savedVal == 'false') {
                resolvedValue = false;
              } else {
                var gVal = alarm['value'];
                if (gVal is bool) {
                  resolvedValue = gVal;
                } else {
                  resolvedValue = defaultValue == true;
                }
              }
            } else {
              resolvedValue = _validateAndCastValue(widgetTypeId, savedVal, defaultValue);
            }
          }

          return ConstantSettingModel(
            sNo: sNo,
            title: title,
            widgetTypeId: widgetTypeId,
            dataType: settingDef['dataType'] ?? 'STRING',
            gemDisplay: settingDef['gemDisplay'] ?? true,
            gemPayload: settingDef['gemPayload'] ?? true,
            ecoGemDisplay: settingDef['ecoGemDisplay'] ?? true,
            ecoGemPayload: settingDef['ecoGemPayload'] ?? true,
            omsGemDisplay: settingDef['omsGemDisplay'] ?? false,
            omsGemPayload: settingDef['omsGemPayload'] ?? false,
            common: settingDef['common'],
            value: ValueNotifier<dynamic>(resolvedValue),
          );
        }).toList();

        return AlarmInConstantModel(
          sNo: alarm['sNo'],
          title: alarm['title'],
          setting: settings,
        );
      }).toList(),
    );
  }

  static dynamic _validateAndCastValue(int widgetTypeId, dynamic val, dynamic defaultVal) {
    if (widgetTypeId == 2) {
      // Switch / Toggle
      if (val is bool) return val;
      if (val == 1 || val == '1' || val == 'true') return true;
      if (val == 0 || val == '0' || val == 'false') return false;
      return defaultVal == true;
    } else if (widgetTypeId == 3) {
      // Time string HH:MM:SS
      if (val is String && val.contains(':')) return val;
      if (defaultVal is String && defaultVal.contains(':')) return defaultVal;
      return '00:00:00';
    } else if (widgetTypeId == 6) {
      // PopUp item sNo (usually int: 1 or 2)
      if (val is int && val > 0) return val;
      if (val != null) {
        int? parsed = int.tryParse(val.toString());
        if (parsed != null && parsed > 0) return parsed;
      }
      if (defaultVal is int) return defaultVal;
      return 1;
    } else if (widgetTypeId == 1) {
      // Text Form Field
      if (val is bool) {
        // Corrupted value from previous shift
        return defaultVal?.toString() ?? '0';
      }
      return val != null ? val.toString() : (defaultVal?.toString() ?? '0');
    }
    return val ?? defaultVal ?? '';
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
