
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHelper {
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _roleKey = 'user_role';
  static const String _countryCodeKey = 'country_code';
  static const String _mobileNumberKey = 'mobile_number';
  static const String _emailKey = 'email';
  static const String _deviceTokenKey = 'deviceToken';
  static const String _confPermissionKey = 'permissionDenied';
  static const String _passwordKey = 'password';

  static Future<void> saveUserDetails({
    required String token,
    required int userId,
    required String userName,
    required String role,
    required String countryCode,
    required String mobileNumber,
    required String email,
    required bool configPermission,
    required String password,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_countryCodeKey, countryCode);
    await prefs.setString(_mobileNumberKey, mobileNumber);
    await prefs.setString(_emailKey, email);
    await prefs.setBool(_confPermissionKey, configPermission);
    await prefs.setString(_passwordKey, password);
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  static Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }


  static Future<String?> getUserRole() async { // admin,
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getCountryCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_countryCodeKey);
  }

  static Future<String?> getMobileNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileNumberKey);
  }

  static Future<String?> getEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<void> clearAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> getDeviceToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceTokenKey);
  }

  static Future<bool?> getConfigPermission() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_confPermissionKey);
  }

  static Future<String?> getUserPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

}