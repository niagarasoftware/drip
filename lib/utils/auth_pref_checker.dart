import 'package:oro_drip_irrigation/utils/shared_preferences_helper.dart';

import '../models/user_model.dart';
import 'enums.dart';

class AuthPrefChecker {
  static Future<UserModel?> getLoggedInUser() async {
    final token = await PreferenceHelper.getToken();
    final mobile = await PreferenceHelper.getMobileNumber();
    final userId = await PreferenceHelper.getUserId();
    final roleString = await PreferenceHelper.getUserRole();

    if (token == null || token.isEmpty) return null;
    if (mobile == null || mobile.isEmpty) return null;
    if (userId == null || userId == 0) return null;
    if (roleString == null || roleString.isEmpty) return null;

    return UserModel(
      token: token,
      id: userId,
      name: await PreferenceHelper.getUserName() ?? '',
      role: getRoleFromString(roleString),
      countryCode: await PreferenceHelper.getCountryCode() ?? '',
      mobileNo: mobile,
      email: await PreferenceHelper.getEmail() ?? '',
      configPermission:
      await PreferenceHelper.getConfigPermission() ?? false,
      password: await PreferenceHelper.getUserPassword() ?? '',
    );
  }

  static UserRole getRoleFromString(String role) {
    switch (role) {
      case '0':
        return UserRole.superAdmin;
      case '1':
        return UserRole.admin;
      case '2':
        return UserRole.dealer;
      case '3':
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }
}