import 'dart:ui';

import 'package:oro_drip_irrigation/utils/constants.dart';

import 'constant_setting_model.dart';
import 'constant_setting_type_Model.dart';

class EcPhInConstantModel{
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  final dynamic location;
  List<PopUpItemModel> ecPopup;
  List<PopUpItemModel> phPopup;
  List<List<ConstantSettingModel>> setting = [];
  List<ConstantSettingModel> ecSetting = [];
  List<ConstantSettingModel> phSetting = [];

  EcPhInConstantModel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.location,
    required this.setting,
    required this.ecPopup,
    required this.phPopup,
    required this.ecSetting,
    required this.phSetting,
  });

  factory EcPhInConstantModel.fromJson({
    required objectData,
    required List<dynamic> defaultSetting,
    required List<dynamic> oldSetting,
    required List<dynamic> ec,
    required List<dynamic> ph,
  }){
    print("objectData : $objectData");
    print("defaultSetting : $defaultSetting");
    print("oldSetting : $oldSetting");
    List<PopUpItemModel> ecPopUpList= [];
    List<PopUpItemModel> phPopUpList= [];
    List<ConstantSettingModel> generateEc = defaultSetting.map((setting){
      List<dynamic> oldData = [];
      if(oldSetting.isNotEmpty && oldSetting.any((site) => site['sNo'] == objectData['sNo'])){
        var siteData = oldSetting.firstWhere((site) => site['sNo'] == objectData['sNo']);
        if((siteData['setting'] as List<dynamic>).isNotEmpty){
          oldData = (siteData['setting'][0] as List<dynamic>).where((item) => item['sNo'] == setting['sNo']).toList();
        }
      }
      print("ConstantSettingModel setting : $setting");
      print("ConstantSettingModel oldData : ${oldData.firstOrNull}");
      return ConstantSettingModel.fromJson(setting, oldData.firstOrNull);
    }).toList();

    // create list of PopUpItemModel for ec
    for(var count = 0;count < ec.length;count++){
      if(count == 0){
        ecPopUpList.add(
            PopUpItemModel(sNo: ec[count]['sNo'].toString(), title: ec[count]['name'], color: const Color(0xffE73293))
        );
      }
      if(count == 1){
        ecPopUpList.add(
            PopUpItemModel(sNo: ec[count]['sNo'].toString(), title: ec[count]['name'], color: const Color(0xffEB7C17))
        );
        ecPopUpList.add(
            PopUpItemModel(sNo: [ec[0]['sNo'], ec[1]['sNo']].join('+'), title: 'Average', color: const Color(0xff6B6B6B))
        );
      }
    }

    int indexOfControlSensor = generateEc.indexWhere((ecSetting) => ecSetting.sNo == 8);

    /*if generatedEcControlSensorValue is 0.0 that means no sensor selected
    so i change this value to first ec sensor if available..*/
    if(!generateEc[indexOfControlSensor].value.toString().contains('${AppConstants.ecObjectId}') && ec.isNotEmpty){
      generateEc[indexOfControlSensor].value.value = ec[0]['sNo'].toString();
    }

    /*if generatedEcControlSensorValue is average and if ec list have not 2 sensor*/
    bool generatedEcControlSensorIsAverage = (generateEc[indexOfControlSensor].sNo.toString()).contains('+');
    if(ec.length < 2 && ec.isNotEmpty && generatedEcControlSensorIsAverage){
      generateEc[indexOfControlSensor].value.value = ec[0]['sNo'].toString();
    }

    List<ConstantSettingModel> generatePh = defaultSetting.map((setting){
      List<dynamic> oldData = [];
      if(oldSetting.isNotEmpty && oldSetting.any((site) => site['sNo'] == objectData['sNo'])){
        var siteData = oldSetting.firstWhere((site) => site['sNo'] == objectData['sNo']);
        if((siteData['setting'] as List<dynamic>).length > 1){
          oldData = (siteData['setting'][1] as List<dynamic>).where((item) => item['sNo'] == setting['sNo']).toList();
        }
      }
      return ConstantSettingModel.fromJson(setting, oldData.firstOrNull);
    }).toList();
    for(var count = 0;count < ph.length;count++){
      if(count == 0){
        phPopUpList.add(
            PopUpItemModel(sNo: ph[count]['sNo'].toString(), title: ph[count]['name'], color: const Color(0xffE73293))
        );
      }
      if(count == 1){
        phPopUpList.add(
            PopUpItemModel(sNo: ph[count]['sNo'].toString(), title: ph[count]['name'], color: const Color(0xffEB7C17))
        );
        phPopUpList.add(
            PopUpItemModel(sNo: [ph[0]['sNo'], ph[1]['sNo']].join('+'), title: 'Average', color: const Color(0xff6B6B6B))
        );
      }
    }
    /*if generatedPhControlSensorValue is 0.0 that means no sensor selected
    so i change this value to first ph sensor if available..*/
    if(!generatePh[indexOfControlSensor].value.toString().contains('${AppConstants.ecObjectId}') && ph.isNotEmpty){
      generatePh[indexOfControlSensor].value.value = ph[0]['sNo'].toString();
    }

    /*if generatedPhControlSensorValue is average and if ph list have not 2 sensor*/
    bool generatedPhControlSensorIsAverage = (generatePh[indexOfControlSensor].sNo.toString()).contains('+');
    if(ph.length < 2 && ph.isNotEmpty && generatedPhControlSensorIsAverage){
      generatePh[indexOfControlSensor].value.value = ph[0]['sNo'].toString();
    }
    
    return EcPhInConstantModel(
        objectId: objectData['objectId'],
        sNo: objectData['sNo'],
        name: objectData['name'],
        objectName: objectData['objectName'],
        location: objectData['location'],
        setting: [
          if(ec.isNotEmpty)
            generateEc,
          if(ph.isNotEmpty)
            generatePh,
        ],
        ecPopup: ec.isNotEmpty ? ecPopUpList : [],
        phPopup: ph.isNotEmpty ? phPopUpList : [],
        ecSetting: ec.isNotEmpty ? generateEc : [],
        phSetting: ph.isNotEmpty ? generatePh : [],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'objectId' : objectId,
      'sNo' : sNo,
      'name' : name,
      'objectName' : objectName,
      'location' : location,
      'setting' : setting.map((setting) {
        return setting.map((ecPhSetting) {
          return ecPhSetting.toJson();
        }).toList();
      }).toList(),
    };
  }
}