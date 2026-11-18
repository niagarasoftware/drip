import 'package:oro_drip_irrigation/modules/fertilizer_set/model/channel_setting_model.dart';
import 'package:oro_drip_irrigation/modules/fertilizer_set/model/ec_ph_setting_model.dart';

class FertilizerSiteSettingModel{
  final int objectId;
  final double sNo;
  final String name;
  String recipeName;
  bool select;
  List<ChannelSettingModel> channel;
  bool ecActive;
  bool phActive;
  String ecValue;
  String phValue;
  List<EcPhSettingModel> ec;
  List<EcPhSettingModel> ph;

  FertilizerSiteSettingModel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.recipeName,
    required this.channel,
    required this.ec,
    required this.ecValue,
    required this.ecActive,
    required this.ph,
    required this.phValue,
    required this.phActive,
    required this.select,
  });

  factory FertilizerSiteSettingModel.fromJson(data){
    return FertilizerSiteSettingModel(
        objectId: data['objectId'],
        sNo: data['sNo'],
        name: data['name'],
        recipeName: data['recipeName'] ?? '',
        select: false,
        channel: (data['channel'] as List<dynamic>).map((channel) {
          return ChannelSettingModel.fromJson(channel);
        }).toList(),
        ec: (data['ec'] as List<dynamic>).map((ec) {
          return EcPhSettingModel.fromJson(ec);
        }).toList(),
        ph: (data['ph'] as List<dynamic>).map((ph) {
          return EcPhSettingModel.fromJson(ph);
        }).toList(),
      ecValue: data['ecValue'] ?? '0.0',
      ecActive: data['ecActive'] ?? false,
      phValue: data['phValue'] ?? '0.0',
      phActive: data['phActive'] ?? false,
    );
  }

  FertilizerSiteSettingModel createRecipe(String recipeName){
    var data = toJson();
    data['recipeName'] = recipeName;
    return FertilizerSiteSettingModel.fromJson(data);
  }

  Map<String, dynamic> toJson(){
    return {
      'objectId' : objectId,
      'sNo' : sNo,
      'name' : name,
      'recipeName' : recipeName,
      'channel' : channel.map((channel) => channel.toJson()).toList(),
      'ec' : ec.map((ec) => ec.toJson()).toList(),
      'ph' : ph.map((ph) => ph.toJson()).toList(),
      'ecValue' : ecValue,
      'ecActive' : ecActive,
      'phValue' : phValue,
      'phActive' : phActive,
    };
  }
}