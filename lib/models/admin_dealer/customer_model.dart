class Customer {
  final int userId;
  final String userName;
  final String countryCode;
  final String mobileNumber;

  Customer({
    required this.userId,
    required this.userName,
    required this.countryCode,
    required this.mobileNumber,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      countryCode: json['countryCode'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
    );
  }

  String get fullMobileNumber => '$countryCode$mobileNumber';
}