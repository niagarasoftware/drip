import '../utils/enums.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String mobileNo;
  final String countryCode;
  final UserRole role;
  final String token;
  final bool configPermission;
  final String password;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobileNo,
    required this.countryCode,
    required this.role,
    required this.token,
    required this.configPermission,
    required this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userId'] ?? 0,
      name: json['userName'] ?? '',
      email: json['email'] ?? '',
      mobileNo: json['mobileNumber'] ?? '',
      countryCode: json['countryCode'] ?? '',
      role: _mapRole(json['userType']),
      token: json['accessToken'] ?? '',
      configPermission: json['accessToken'] ?? '',
      password: json['password'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "mobileNo": mobileNo,
    "countryCode": countryCode,
    "role": role,
    "token": token,
    "configPermission": configPermission,
    "password": password,
  };

  static UserRole _mapRole(String? userType) {
    switch (userType) {
      case '1':
        return UserRole.admin;
      case '2':
        return UserRole.dealer;
      case '3':
      default:
        return UserRole.customer;
    }
  }

  factory UserModel.empty() {
    return UserModel(
      id: 0,
      name: '',
      email: '',
      mobileNo: '',
      countryCode: '',
      role: UserRole.customer,
      token: '',
      configPermission: false,
      password: '',
    );
  }

  /// ✅ This allows updating only specific fields
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? mobileNo,
    String? countryCode,
    UserRole? role,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobileNo: mobileNo ?? this.mobileNo,
      countryCode: countryCode ?? this.countryCode,
      role: role ?? this.role,
      token: token ?? this.token,
      configPermission: configPermission,
      password: password,
    );
  }
}