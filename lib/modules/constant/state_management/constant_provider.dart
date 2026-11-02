import 'package:flutter/foundation.dart';
import 'package:oro_drip_irrigation/modules/constant/model/constant_menu_model.dart';
import 'package:oro_drip_irrigation/modules/constant/model/constant_setting_model.dart';
import 'package:oro_drip_irrigation/modules/constant/model/ec_ph_in_constant_model.dart';
import 'package:oro_drip_irrigation/modules/constant/model/normal_critical_alarm_model.dart';
import 'package:oro_drip_irrigation/modules/constant/model/object_in_constant_model.dart';
import 'package:oro_drip_irrigation/modules/constant/widget/arrow_tab.dart';
import 'package:oro_drip_irrigation/utils/constants.dart';
import '../model/constant_setting_type_Model.dart';

class ConstantProvider extends ChangeNotifier{
  Map<String, dynamic> constantDataFromHttp = {};
  Map<String, dynamic> userData = {};
  List<dynamic> deviceList = [];
  List<dynamic> configObjectDataFromHttp = [];
  List<ConstantMenuModel> listOfConstantMenuModel = [];
  List<ConstantSettingModel> general = [];
  List<ConstantSettingModel> globalAlarm = [];
  List<NormalCriticalAlarmModel> normalCriticalAlarm = [];
  List<ObjectInConstantModel> pump = [];
  List<ObjectInConstantModel> filterSite = [];
  List<ObjectInConstantModel> filter = [];
  List<ObjectInConstantModel> mainValve = [];
  List<ObjectInConstantModel> valve = [];
  List<ObjectInConstantModel> waterMeter = [];
  List<ObjectInConstantModel> fertilizerSite = [];
  List<ObjectInConstantModel> channel = [];
  List<EcPhInConstantModel> ecPhSensor = [];
  List<ObjectInConstantModel> moisture = [];
  List<ObjectInConstantModel> level = [];
  List<ConstantSettingModel> defaultPumpSetting = [];
  List<ConstantSettingModel> defaultFilterSiteSetting = [];
  List<ConstantSettingModel> defaultFilterSetting = [];
  List<ConstantSettingModel> defaultMainValveSetting = [];
  List<ConstantSettingModel> defaultValveSetting = [];
  List<ConstantSettingModel> defaultWaterMeterSetting = [];
  List<ConstantSettingModel> defaultFertilizerSiteSetting = [];
  List<ConstantSettingModel> defaultChannelSetting = [];
  List<ConstantSettingModel> defaultEcPhSetting = [];
  List<ConstantSettingModel> defaultMoistureSetting = [];
  List<ConstantSettingModel> defaultLevelSetting = [];
  List<ConstantSettingModel> defaultNormalCriticalAlarmSetting = [];
  List<PopUpItemModel> filterSiteWhileBackwash = [];
  List<PopUpItemModel> mainValveMode = [];
  List<PopUpItemModel> sourceType = [];
  List<PopUpItemModel> fertilizerSiteControlFlag = [];
  List<PopUpItemModel> fertilizerChannelMode = [];
  List<PopUpItemModel> moistureMode = [];
  List<PopUpItemModel> alarmOnStatus = [];
  List<PopUpItemModel> alarmResetAfterIrrigation = [];

  String getName(dynamic sNo){
    var name = '';
    for(var n in configObjectDataFromHttp){
      if(n['sNo'].toString() == sNo.toString()){
        name = n['name'];
      }
    }
    return name.isEmpty ? 'Location N/A' : name;
  }

  List<PopUpItemModel> generatePopUpItemModel({
    required Map<String, dynamic> defaultData,
    required String keyName
  }){
    return (defaultData[keyName] as List<dynamic>).map((setting) {
      return PopUpItemModel.fromJson(setting);
    }).toList();
  }

  List<ConstantSettingModel> generateDefaultSetting({
    required Map<String, dynamic> defaultData,
    required String keyName
  }){
    return (defaultData[keyName] as List<dynamic>).map((setting) {
      return ConstantSettingModel.fromJson(setting, null);
    }).toList();
  }

  List<ObjectInConstantModel> generateObjectInConstantModel(
      {
        required List<dynamic> listOfObject,
        required Map<String, dynamic> defaultData,
        required Map<String, dynamic> constantOldData,
        required String keyName
      }){
    return listOfObject.map((object){
      List<dynamic> oldSetting = (constantOldData[keyName] as List<dynamic>).where((setting) => setting['sNo'] == object['sNo']).toList();
      return ObjectInConstantModel.fromJson(
          objectData: object,
          defaultSetting: defaultData[keyName] as List<dynamic>,
          oldSetting: oldSetting.isNotEmpty ? oldSetting.first['setting'] : []
      );
    }).toList();
  }

  bool checkAnySettingAvailable({
    required List<ConstantSettingModel> defaultSetting,
  }){
    return defaultSetting.any((setting) => setting.ecoGemDisplay == true);
  }

  void updateConstant({required constantData, required configMakerData, required userDataAndMasterData}){
    try{
      constantDataFromHttp = constantData['data'];
      userData = userDataAndMasterData;
      configObjectDataFromHttp = configMakerData['data']['configObject'];

      Map<String, dynamic> defaultData = constantDataFromHttp['default'];
      deviceList = defaultData['nodeList'];
      if(AppConstants.ecoGemModelList.contains(userData['modelId'])){
        deviceList.insert(0, userData);
      }
      Map<String, dynamic> constantOldData = constantDataFromHttp['constant'];
      // update constant menu
      listOfConstantMenuModel = (defaultData['constantMenu'] as List<dynamic>).map((menu){
        return ConstantMenuModel(
            dealerDefinitionId: menu['dealerDefinitionId'],
            parameter: menu['parameter'],
            arrowTabState: ValueNotifier(menu['dealerDefinitionId'] == AppConstants.generalInConstant ? ArrowTabState.onProgress : ArrowTabState.inComplete)
        );
      }).toList();
      if(AppConstants.ecoGemModelList.contains(userData['modelId'])){
        listOfConstantMenuModel = listOfConstantMenuModel.where((menuModel){
          if(menuModel.dealerDefinitionId == AppConstants.levelSensorInConstant){
            return checkAnySettingAvailable(defaultSetting: defaultLevelSetting);
          }else if(menuModel.dealerDefinitionId == AppConstants.fertilizerSiteInConstant){
            return checkAnySettingAvailable(defaultSetting: defaultFertilizerSiteSetting);
          }else if(menuModel.dealerDefinitionId == AppConstants.ecPhInConstant){
            return checkAnySettingAvailable(defaultSetting: defaultEcPhSetting);
          }else if(menuModel.dealerDefinitionId == AppConstants.mainValveInConstant){
            return checkAnySettingAvailable(defaultSetting: defaultMainValveSetting);
          }else{
            return true;
          }
        }).toList();
      }
      //update object
      List<dynamic> listOfPumpObject = [];
      List<dynamic> listOfFilterSiteObject = [];
      List<dynamic> listOfFilterObject = [];
      List<dynamic> listOfMainValveObject = [];
      List<dynamic> listOfValveObject = [];
      List<dynamic> listOfWaterMeterObject = [];
      List<dynamic> listOfFertilizerSiteObject = configMakerData['data']['fertilizerSite'];
      List<dynamic> listOfChannelObject = [];
      List<dynamic> listOfEcObject = [];
      List<dynamic> listOfPhObject = [];
      List<dynamic> listOfMoistureObject = [];
      List<dynamic> listOfLevelObject = [];
      List<dynamic> listOfIrrigationLineObject = [];

      for (var object in configObjectDataFromHttp) {
        if([AppConstants.irrigationLineObjectId, AppConstants.fertilizerSiteObjectId, AppConstants.filterSiteObjectId].contains(object['objectId']) || object["controllerId"] != null){
          if(object['objectId'] == AppConstants.pumpObjectId){
            listOfPumpObject.add(object);
          }else if(object['objectId'] == AppConstants.filterSiteObjectId){
            listOfFilterSiteObject.add(object);
          }else if(object['objectId'] == AppConstants.filterObjectId){
            listOfFilterObject.add(object);
          }else if(object['objectId'] == AppConstants.mainValveObjectId){
            listOfMainValveObject.add(object);
          }else if(object['objectId'] == AppConstants.valveObjectId || object['objectId'] == AppConstants.flowControlValveObjectId){
            listOfValveObject.add(object);
          }else if(object['objectId'] == AppConstants.waterMeterObjectId || object['objectId'] == AppConstants.analogWaterMeterObjectId){
            listOfWaterMeterObject.add(object);
          }else if(object['objectId'] == AppConstants.channelObjectId){
            listOfChannelObject.add(object);
          }else if(object['objectId'] == AppConstants.ecObjectId){
            listOfEcObject.add(object);
          }else if(object['objectId'] == AppConstants.phObjectId){
            listOfPhObject.add(object);
          }else if(object['objectId'] == AppConstants.moistureObjectId){
            listOfMoistureObject.add(object);
          }else if(object['objectId'] == AppConstants.levelObjectId){
            listOfLevelObject.add(object);
          }else if(object['objectId'] == AppConstants.irrigationLineObjectId){
            listOfIrrigationLineObject.add(object);
          }
        }
      }

      print("listOfFertilizerSiteObject => $listOfFertilizerSiteObject");
      // update general
      general = (defaultData['general'] as List<dynamic>)
          .map((menu){
        List<dynamic> oldValue = [];
        List<dynamic> generalOldData = constantOldData['general'] as List<dynamic>;
        if(generalOldData.any((oldSetting) => oldSetting['sNo'] == menu['sNo'])){
          oldValue = generalOldData.where((oldSetting) => oldSetting['sNo'] == menu['sNo']).toList();
        }
        return ConstantSettingModel.fromJson(menu, oldValue.firstOrNull);
      }).toList();

      // update globalAlarm
      globalAlarm = (defaultData['globalAlarm'] as List<dynamic>).map((menu){
        List<dynamic> oldValue = [];
        List<dynamic> generalOldData = constantOldData['globalAlarm'] as List<dynamic>;
        if(generalOldData.any((oldSetting) => oldSetting['sNo'] == menu['sNo'])){
          oldValue = generalOldData.where((oldSetting) => oldSetting['sNo'] == menu['sNo']).toList();
        }
        return ConstantSettingModel.fromJson(menu, oldValue.firstOrNull);
      }).toList();


      // update normal and critical
      alarmOnStatus = generatePopUpItemModel(defaultData: defaultData, keyName: 'alarmOnStatus');
      alarmResetAfterIrrigation = generatePopUpItemModel(defaultData: defaultData, keyName: 'alarmResetAfterIrrigation');
      defaultNormalCriticalAlarmSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'normalCriticalAlarm');
      if (kDebugMode) {
        print("listOfIrrigationLineObject : $listOfIrrigationLineObject");
      }
      normalCriticalAlarm = listOfIrrigationLineObject.map((line){
        if (kDebugMode) {
          print("constantOldData['normalCriticalAlarm'] : $constantOldData");
        }
        List<dynamic> lineData = (constantOldData['normalCriticalAlarm'] as List<dynamic>).where((oldLine) => oldLine['sNo'] == line['sNo']).toList();
        return NormalCriticalAlarmModel.fromJson(
            objectData: line,
            defaultSetting: defaultData['normalCriticalAlarm'],
            globalAlarm: defaultData['globalAlarm'],
            oldSetting: lineData.firstOrNull,
            userData: userData
        );
      }).toList();
      if (kDebugMode) {
        print('normalCriticalAlarm updated..');
      }



      // update level
      sourceType = generatePopUpItemModel(defaultData: defaultData, keyName: 'sourceType');
      defaultLevelSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'levelSensor');
      level = generateObjectInConstantModel(listOfObject: listOfLevelObject, defaultData: defaultData, constantOldData: constantOldData, keyName: 'levelSensor');
      if (kDebugMode) {
        print('level updated..');
      }
      defaultPumpSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'pump');
      pump = generateObjectInConstantModel(listOfObject: listOfPumpObject, defaultData: defaultData, constantOldData: constantOldData, keyName: 'pump');
      if (kDebugMode) {
        print('pump updated..');
      }

      // update filterSite
      filterSiteWhileBackwash = generatePopUpItemModel(defaultData: defaultData, keyName: 'filterSiteWhileBackwash');
      defaultFilterSiteSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'filterSite');
      filterSite = generateObjectInConstantModel(listOfObject: listOfFilterSiteObject, defaultData: defaultData, constantOldData: constantOldData, keyName: 'filterSite');
      if (kDebugMode) {
        print('filterSite updated..');
      }

      // update filter
      defaultFilterSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'filter');
      filter = generateObjectInConstantModel(listOfObject: listOfFilterObject, defaultData: defaultData, constantOldData: constantOldData, keyName: 'filter');
      if (kDebugMode) {
        print('filter updated..');
      }

      //update mainValve
      mainValveMode = generatePopUpItemModel(defaultData: defaultData, keyName: 'mainValveMode');
      defaultMainValveSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'mainValve');
      mainValve = generateObjectInConstantModel(listOfObject: listOfMainValveObject, defaultData: defaultData, constantOldData: constantOldData, keyName: 'mainValve');
      if (kDebugMode) {
        print('mainValve updated..');
      }

      // update valve
      defaultValveSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'valve');
      valve = generateObjectInConstantModel(listOfObject: listOfValveObject, defaultData: defaultData, constantOldData: constantOldData, keyName: 'valve');
      if (kDebugMode) {
        print('valve updated..');
      }

      // update waterMeter
      defaultWaterMeterSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'waterMeter');
      waterMeter = generateObjectInConstantModel(listOfObject: listOfWaterMeterObject, defaultData: defaultData, constantOldData: constantOldData, keyName: 'waterMeter');
      if (kDebugMode) {
        print('waterMeter updated..');
      }

      // update fertilizerSite
      fertilizerSiteControlFlag = generatePopUpItemModel(defaultData: defaultData, keyName: 'fertilizerSiteControlFlag');
      defaultFertilizerSiteSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'fertilizerSite');
      fertilizerSite = generateObjectInConstantModel(listOfObject: listOfFertilizerSiteObject, defaultData: defaultData, constantOldData: constantOldData, keyName: 'fertilizerSite');
      for(var site in fertilizerSite){
        for(var setting in site.setting){
          if(setting.sNo == 4 && (setting.value.value == 3 || setting.value.value == 4)){
            setting.value.value = 1;
          }
        }
      }
      if (kDebugMode) {
        print('fertilizerSite updated..');
      }

      // update channel
      fertilizerChannelMode = generatePopUpItemModel(defaultData: defaultData, keyName: 'fertilizerChannelMode');
      defaultChannelSetting = generateDefaultSetting(defaultData: defaultData, keyName: "fertilizerChannel");
      channel = generateObjectInConstantModel(listOfObject: listOfChannelObject, defaultData: defaultData, constantOldData: constantOldData, keyName: "fertilizerChannel");
      if (kDebugMode) {
        print('channel updated..');
      }
      print("listOfFertilizerSiteObject => $listOfFertilizerSiteObject");
      // update ec ph
      if(listOfFertilizerSiteObject.isNotEmpty){
        // find out and filter the fertilizer site has ec or ph
        defaultEcPhSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'ecPhSensor');
        List<dynamic> fertilizerSiteWithEcPh = listOfFertilizerSiteObject.where((site){
          print("listOfEcObject : $listOfEcObject");
          print("site : $site");
          bool ecAvailable = listOfEcObject.any((ecSensor) => site['ec'].contains(ecSensor['sNo']));
          bool phAvailable = listOfPhObject.any((phSensor) => site['ph'].contains(phSensor['sNo']));
          print('ecAvailable : $ecAvailable');
          print('phAvailable : $phAvailable');
          if(ecAvailable || phAvailable){
            return true;
          }else{
            return false;
          }
        }).toList();
        print("fertilizerSiteWithEcPh : $fertilizerSiteWithEcPh");
        ecPhSensor = fertilizerSiteWithEcPh.map((site){
          return EcPhInConstantModel.fromJson(
              objectData: site,
              defaultSetting: defaultData["ecPhSensor"],
              oldSetting: constantOldData["ecPhSensor"],
              ec: listOfEcObject.where((ecSensor) => site['ec'].contains(ecSensor['sNo'])).toList(),
              ph: listOfPhObject.where((phSensor) => site['ph'].contains(phSensor['sNo'])).toList()
          );
        }).toList();
        for(var ecPh in ecPhSensor){
          print("ecph :::: ${ecPh.toJson()}");
        }
      }
      if (kDebugMode) {
        print('ecPh updated..');
      }

      // update moisture
      moistureMode = generatePopUpItemModel(defaultData: defaultData, keyName: 'moistureMode');
      defaultMoistureSetting = generateDefaultSetting(defaultData: defaultData, keyName: 'moistureSensor');
      moisture = generateObjectInConstantModel(listOfObject: listOfMoistureObject, defaultData: defaultData, constantOldData: constantOldData, keyName: 'moistureSensor');
      notifyListeners();
      if (kDebugMode) {
        print('moisture updated..');
      }


    }catch(e, stackTrace){
      print('Error on update constant :: $e');
      print('stackTrace on update constant :: $stackTrace');
    }

    notifyListeners();
  }

  String getDeviceDetails({required String key, required int? controllerId}){

    String value = '';
    for(var device in deviceList){
      if(controllerId != null && device['controllerId'] == controllerId){
        value = device[key];
      }
    }
    return value;
  }

  dynamic payloadValidate(value){
    if(value is bool){
      return value ? 1 : 0;
    }else if(value is String && AppConstants.ecoGemModelList.contains(userData['modelId'])){
      if(value.contains(':')){
        return value.split(':').join(',');
      }
      return value.isEmpty ? 0 : value;
    }else{
      if(value is String && value.isEmpty){
        return '0';
      }
      return value;
    }
  }

  String getGeneralPayload(){
    return general.where((setting) {
      return AppConstants.gemModelList.contains(userData['modelId']) ?  setting.gemPayload : setting.ecoGemPayload;
    }).map((setting) => payloadValidate(setting.value.value)).join(',');
  }

  String getGlobalAlarmPayload(){
    return globalAlarm.where((setting) {
      return AppConstants.gemModelList.contains(userData['modelId']) ?  setting.gemPayload : setting.ecoGemPayload;
    }).map((setting) => payloadValidate(setting.value.value)).join(',');
  }

  String getEcoGemPayloadForGlobalAlarm(){
    return [
      for(var setting in globalAlarm)
        if(setting.ecoGemPayload)
          ...[
            setting.sNo,
            payloadValidate(setting.value.value)
          ]
    ].join(',');
  }

  String serialNumberFormatForEcoGem(double sNo){
    List<String> sNoSplitList = sNo.toString().split('.');
    if(sNoSplitList[1].length == 2){
      sNoSplitList[1] += '0';
    }
    return sNoSplitList.join(',');
  }

  String getObjectInConstantPayload(List<ObjectInConstantModel> object){
    return object.map((object){
      bool isGem = AppConstants.gemModelList.contains(userData['modelId']);
      bool isOms = AppConstants.omsGemList.contains(userData['modelId']);
      var objectSno = (isGem || isOms) ? object.sNo : serialNumberFormatForEcoGem(object.sNo);
      return [
        objectSno,
        ...object.setting.where((setting){
          return AppConstants.gemModelList.contains(userData['modelId']) ?  setting.gemPayload : setting.ecoGemPayload;
        }).map((setting){
          return payloadValidate(setting.value.value);
        })
      ].join(',');
    }).join(';');
  }

  String getFertilizerSitePayload(){
    return List.generate(fertilizerSite.length, (siteIndex){
      return [
        fertilizerSite[siteIndex].sNo,
        ...fertilizerSite[siteIndex].setting.where((setting){
          return AppConstants.gemModelList.contains(userData['modelId']) ?  setting.gemPayload : setting.ecoGemPayload;
        }).map((setting){
          return payloadValidate(setting.value.value);
        }),
        if(ecPhSensor.isNotEmpty && ecPhSensor[siteIndex].ecSetting.isNotEmpty)
          ...ecPhSensor[siteIndex].ecSetting.where((setting){
            return AppConstants.gemModelList.contains(userData['modelId']) ?  setting.gemPayload : setting.ecoGemPayload;
          }).map((setting){
            return payloadValidate(setting.value.value);
          })
        else
          ...List.generate(defaultEcPhSetting.length, (index){
            return payloadValidate(defaultEcPhSetting[index].value.value);
          }),
        if(ecPhSensor.isNotEmpty && ecPhSensor[siteIndex].phSetting.isNotEmpty)
          ...ecPhSensor[siteIndex].phSetting.where((setting){
            return AppConstants.gemModelList.contains(userData['modelId']) ?  setting.gemPayload : setting.ecoGemPayload;
          }).map((setting){
            return payloadValidate(setting.value.value);
          })
        else
          ...List.generate(defaultEcPhSetting.length, (index){
            return payloadValidate(defaultEcPhSetting[index].value.value);
          }),
      ].join(',');
    }).join(';');
  }

  String getNormalCriticalAlarm(){
    int alarmUniqueSno = 0;
    List<dynamic> payloadList = [];
    for(var line in normalCriticalAlarm){
      for(var alarmIndex = 0;alarmIndex < line.normal.length;alarmIndex++){
        alarmUniqueSno++;
        payloadList.add(
          [
            alarmUniqueSno,
            line.sNo,
            line.normal[alarmIndex].sNo,
            ...line.normal[alarmIndex].setting.where((setting){
              return (setting.gemPayload && setting.common == null);
            }).map((setting){
              return payloadValidate(setting.value.value);
            }),
            ...line.critical[alarmIndex].setting.where((setting){
              return (setting.gemPayload && setting.common == null);
            }).map((setting){
              return payloadValidate(setting.value.value);
            }),
            ...line.normal[alarmIndex].setting.where((setting){
              return (setting.gemPayload && setting.common != null);
            }).map((setting){
              return payloadValidate(setting.value.value);
            }),
            line.normal[alarmIndex].title,

          ].join(','),
        );
      }
    }
    return payloadList.join(';');
  }

  String getNormalCriticalAlarmForEcoGem(){
    List<dynamic> payloadList = [];
    for(var line in normalCriticalAlarm){
      for(var alarmIndex = 0;alarmIndex < line.normal.length;alarmIndex++){
        payloadList.add(
          [
            line.normal[alarmIndex].sNo,
            ...line.normal[alarmIndex].setting.where((setting){
              return (setting.ecoGemPayload);
            }).map((setting){
              return payloadValidate(setting.value.value);
            }),
          ].join(','),
        );
      }
    }
    return payloadList.join(';');
  }

  String getFilterSitePayload(){
    return filterSite.map((site){
      List<ObjectInConstantModel> filterList = filter.where((filter) {
        return filter.location == site.sNo;
      }).toList();
      String ecoGemFilterSetting =
          '${filterList.isNotEmpty ? payloadValidate(filterList[0].setting[0].value.value) : '00,00,00'}'
          ',${filterList.length > 1 ? payloadValidate(filterList[1].setting[0].value.value) : '00,00,00'}';
      bool isGem = AppConstants.gemModelList.contains(userData['modelId']);
      var siteSno = isGem ? site.sNo : site.sNo.toString().split('.').join(',');
      return [
        siteSno,
        //filter setting when gem
        if(AppConstants.gemModelList.contains(userData['modelId']))
          filterList.map((filter){
            return filter.setting.map((setting){
              return payloadValidate(setting.value.value);
            }).first;
          }).join('_'),
        //filter setting when eco gem
        if(AppConstants.ecoGemModelList.contains(userData['modelId']))
          ecoGemFilterSetting,
        ...site.setting.where((setting){
          return AppConstants.gemModelList.contains(userData['modelId']) ?  setting.gemPayload : setting.ecoGemPayload;
        }).map((setting){
          return payloadValidate(setting.value.value);
        })
      ].join(',');
    }).join(';');
  }
}