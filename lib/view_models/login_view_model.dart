import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/repository.dart';
import '../utils/shared_preferences_helper.dart';

class LoginViewModel extends ChangeNotifier {

  bool isLoading = false;
  String errorMessage = "";

  String countryCode = '91';
  late TextEditingController mobileNoController;
  late TextEditingController passwordController;
  bool isObscure = true;

  final ApiRepository repository;
  final Function(String) onLoginSuccess;

  LoginViewModel({required this.repository,
    required this.onLoginSuccess}) {
    initState();
  }

  void initState() {
    mobileNoController = TextEditingController();
    passwordController = TextEditingController();
   }

  void onIsObscureChanged() {
    isObscure = !isObscure;
    notifyListeners();
  }

  Future<void> login() async {

    if(!kIsWeb) {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.getToken().then((String? token) async{
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('deviceToken', token ?? '' );
      });
    }
    final token = await PreferenceHelper.getDeviceToken();

    isLoading = true;
    errorMessage = "";
    notifyListeners();

    try {
      String mobileNumber = mobileNoController.text.trim();
      String password = passwordController.text.trim();

      if (mobileNumber.isEmpty || password.isEmpty) {
        isLoading = false;
        errorMessage = "Both fields are required!";
        notifyListeners();
        return;
      }else if(mobileNumber.length < 6 || password.length < 5) {
        isLoading = false;
        errorMessage = "Invalid Mobile number or Password!";
        notifyListeners();
        return;
      } else if(!kIsWeb && (token == null || token.isEmpty)){
        print("token in the else :: $token");
        isLoading = false;
        errorMessage = "Device token not generated";
        notifyListeners();
        return;
      }

      String cleanedCountryCode = countryCode.replaceAll("+", "");
      Map<String, Object> body = {
        'countryCode' : cleanedCountryCode,
        'mobileNumber': mobileNumber,
        'password': password,
        'deviceToken': token ?? '',
        'isMobile' : kIsWeb? false : true,
      };

      final response = await repository.checkLoginAuth(body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['code'] == 200) {
        final userData = data['data']['user'];
        await PreferenceHelper.saveUserDetails(
          token: userData['accessToken'],
          userId: userData['userId'],
          userName: userData['userName'],
          password: password,
          role: userData['userType'],
          countryCode: cleanedCountryCode,
          mobileNumber: mobileNumber,
          email: userData['email'],
          configPermission: userData['permissionDenied'] ?? false,
         );
        onLoginSuccess(data['message']);
      } else {
        isLoading = false;
        errorMessage = data['message'];
        notifyListeners();
      }
    } catch (error) {
      print("error:${error.toString()}");
      isLoading = false;
      debugPrint('$error');
      errorMessage = "Unexpected error occurred.";
      notifyListeners();
    }
  }
}