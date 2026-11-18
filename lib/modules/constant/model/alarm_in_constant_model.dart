import 'package:oro_drip_irrigation/modules/constant/model/constant_setting_model.dart';

class AlarmInConstantModel{
  final int sNo;
  final String title;
  List<ConstantSettingModel> setting = [];

  AlarmInConstantModel({
    required this.sNo,
    required this.title,
    required this.setting,
  });

  factory AlarmInConstantModel.fromJson({
    required objectData,
    required List<dynamic> defaultSetting,
    required List<dynamic> oldSetting
  }){
    return AlarmInConstantModel(
        sNo: objectData['sNo'],
        title: objectData['title'],
        setting : defaultSetting.map((setting){
          List<dynamic> oldData = [];
          if(oldSetting.isNotEmpty){
            oldData = oldSetting[0]['setting'].where((oldSetting) => oldSetting['sNo'] == setting['sNo']).toList();
          }
          return ConstantSettingModel.fromJson(setting, oldData.firstOrNull);
        }).toList()
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'sNo' : sNo,
      'title' : title,
      'setting' : setting.map((setting) => setting.toJson()).toList()
    };
  }
}