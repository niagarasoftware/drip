class BluDevice {
  String address;
  String? name;

  static const int disconnected = 0;
  static const int connecting = 1;
  static const int connected = 2;

  BluDevice({required this.address, this.name});

  factory BluDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluDevice(address: map["address"], name: map["name"]);
  }
}