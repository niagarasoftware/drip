import 'channel_for_each_valve_model.dart';

class ValveWithCentralLocalChannelModel{
  final int objectId;
  final double sNo;
  final String name;
  final String objectName;
  String quantity;
  ChannelForEachValveModel? central1;
  ChannelForEachValveModel? central2;
  ChannelForEachValveModel? central3;
  ChannelForEachValveModel? central4;
  ChannelForEachValveModel? central5;
  ChannelForEachValveModel? central6;
  ChannelForEachValveModel? central7;
  ChannelForEachValveModel? central8;
  ChannelForEachValveModel? local1;
  ChannelForEachValveModel? local2;
  ChannelForEachValveModel? local3;
  ChannelForEachValveModel? local4;
  ChannelForEachValveModel? local5;
  ChannelForEachValveModel? local6;
  ChannelForEachValveModel? local7;
  ChannelForEachValveModel? local8;

  ValveWithCentralLocalChannelModel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.objectName,
    required this.quantity,
    required this.central1,
    required this.central2,
    required this.central3,
    required this.central4,
    required this.central5,
    required this.central6,
    required this.central7,
    required this.central8,
    required this.local1,
    required this.local2,
    required this.local3,
    required this.local4,
    required this.local5,
    required this.local6,
    required this.local7,
    required this.local8,
  });

  ChannelForEachValveModel getCentralChannel({required int channelNo}){
    if(channelNo == 0){
      return central1!;
    }else if(channelNo == 1){
      return central2!;
    }else if(channelNo == 2){
      return central3!;
    }else if(channelNo == 3){
      return central4!;
    }else if(channelNo == 4){
      return central5!;
    }else if(channelNo == 5){
      return central6!;
    }else if(channelNo == 6){
      return central7!;
    }else{
      return central8!;
    }
  }

  ChannelForEachValveModel getLocalChannel({required int channelNo}){
    if(channelNo == 0){
      return local1!;
    }else if(channelNo == 1){
      return local2!;
    }else if(channelNo == 2){
      return local3!;
    }else if(channelNo == 3){
      return local4!;
    }else if(channelNo == 4){
      return local5!;
    }else if(channelNo == 5){
      return local6!;
    }else if(channelNo == 6){
      return local7!;
    }else{
      return local8!;
    }
  }

  factory ValveWithCentralLocalChannelModel.fromJson(data){
    return ValveWithCentralLocalChannelModel(
        objectId: data['objectId'],
        sNo: data['sNo'],
        name: data['name'],
        objectName: data['objectName'],
        quantity: data['quantity'].toString(),
        central1 : (data['central1'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['central1']) : null,
        central2 : (data['central2'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['central2']) : null,
        central3 : (data['central3'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['central3']) : null,
        central4 : (data['central4'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['central4']) : null,
        central5 : (data['central5'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['central5']) : null,
        central6 : (data['central6'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['central6']) : null,
        central7 : (data['central7'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['central7']) : null,
        central8 : (data['central8'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['central8']) : null,
        local1 : (data['local1'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['local1']) : null,
        local2 : (data['local2'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['local2']) : null,
        local3 : (data['local3'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['local3']) : null,
        local4 : (data['local4'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['local4']) : null,
        local5 : (data['local5'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['local5']) : null,
        local6 : (data['local6'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['local6']) : null,
        local7 : (data['local7'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['local7']) : null,
        local8 : (data['local8'] as Map<String, dynamic>).isNotEmpty ? ChannelForEachValveModel.fromJson(data['local8']) : null,
    );
  }


  Map<String, dynamic> toJson(){
    return {
      'objectId' : objectId,
      'sNo' : sNo,
      'name' : name,
      'objectName' : objectName,
      'quantity' : 0,
      'central1' : central1 != null ? central1!.toJson() : {},
      'central2' : central2 != null ? central2!.toJson() : {},
      'central3' : central3 != null ? central3!.toJson() : {},
      'central4' : central4 != null ? central4!.toJson() : {},
      'central5' : central5 != null ? central5!.toJson() : {},
      'central6' : central6 != null ? central6!.toJson() : {},
      'central7' : central7 != null ? central7!.toJson() : {},
      'central8' : central8 != null ? central8!.toJson() : {},
      'local1' : local1 != null ? local1!.toJson() : {},
      'local2' : local2 != null ? local2!.toJson() : {},
      'local3' : local3 != null ? local3!.toJson() : {},
      'local4' : local4 != null ? local4!.toJson() : {},
      'local5' : local5 != null ? local5!.toJson() : {},
      'local6' : local6 != null ? local6!.toJson() : {},
      'local7' : local7 != null ? local7!.toJson() : {},
      'local8' : local8 != null ? local8!.toJson() : {},
    };
  }

}