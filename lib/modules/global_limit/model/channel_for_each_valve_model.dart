class ChannelForEachValveModel{
  final double sNo;
  String value;

  ChannelForEachValveModel({
    required this.sNo,
    required this.value,
  });

  factory ChannelForEachValveModel.fromJson(data){
    return ChannelForEachValveModel(
        sNo: data['sNo'],
        value: data['value']
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'sNo' : sNo,
      'value' : value,
    };
  }

}