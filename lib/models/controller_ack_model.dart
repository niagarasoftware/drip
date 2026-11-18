class ControllerAckModel {
  final String code;
  final String name;
  final String payloadCode;

  ControllerAckModel({required this.code, required this.name, required this.payloadCode});

  factory ControllerAckModel.fromJson(Map<String, dynamic> json) {
    return ControllerAckModel(
        code: json['Code'],
        name: json['Name'],
        payloadCode: json['PayloadCode']
    );
  }
}