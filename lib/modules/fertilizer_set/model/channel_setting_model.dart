class ChannelSettingModel{
  final int objectId;
  final double sNo;
  final String name;
  int active;
  String method;
  String timeValue;
  String quantityValue;

  ChannelSettingModel({
    required this.objectId,
    required this.sNo,
    required this.name,
    required this.active,
    required this.method,
    required this.timeValue,
    required this.quantityValue,
  });

  factory ChannelSettingModel.fromJson(data){
    return ChannelSettingModel(
        objectId: data['objectId'],
        sNo: data['sNo'],
        name: data['name'],
        active: data['active'] ?? 0,
        method: (data['method'] == 'Pro.qty per 1000L') ? 'Pro.quant per 1000L' : (data['method'] ?? 'Time'),
        timeValue: data['timeValue'] ?? '00:00:00',
        quantityValue: data['quantityValue'] ?? '0',
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'objectId' : objectId,
      'sNo' : sNo,
      'name' : name,
      'active' : active,
      'method' : method,
      'timeValue' : timeValue,
      'quantityValue' : quantityValue,
    };
  }
}
// Time
// Pro.time
// Quantity
// Pro.quantity
// Pro.quant per 1000L