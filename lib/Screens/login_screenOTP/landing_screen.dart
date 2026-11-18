import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
 import 'package:shared_preferences/shared_preferences.dart';

 import '../../repository/repository.dart';
import '../../services/http_service.dart';
import '../../utils/enums.dart';
import '../../utils/shared_preferences_helper.dart';
import '../../views/common/login/login_screen.dart';
import 'login_screenotp.dart';
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin{
  bool _isLoading = true;
  bool _isSucceed = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkAuthentication();
  }

  @override
  void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: 400,
          width: 200,
          child: _isLoading ? _buildLoadingWidget() : _isSucceed ? _buildSuccessWidget() : _buildErrorWidget(),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lottie/check.json'),
          const LinearProgressIndicator()
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lottie/error.json'),
          const Text('Already logged in!')
        ],
      ),
    );
  }

  Widget _buildSuccessWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lottie/success.json'),
        ],
      ),
    );
  }
  UserRole getRoleFromString(String? role) {
    switch (role?.toLowerCase()) {
      case '0':
        return UserRole.superAdmin;
      case '1':
        return UserRole.admin;
      case '2':
        return UserRole.dealer;
      case '3':
        return UserRole.customer;
      case 'sub user':
        return UserRole.subUser;
      default:
        return UserRole.customer;
    }
  }

  Future<void> checkAuthentication() async {
    try {
      final roleString = await PreferenceHelper.getUserRole();
      final int? userId = await PreferenceHelper.getUserId(); // already int
      final userName = await PreferenceHelper.getUserName();
      final countryCode = await PreferenceHelper.getCountryCode();
      final deviceToken = await PreferenceHelper.getDeviceToken();
      final email = await PreferenceHelper.getEmail();
      final role = getRoleFromString(roleString);

      // If no userId saved → go to login immediately
      if (userId == null || userId == 0) {
        _navigateTo( LoginScreenOTP());
        return;
      }

      final data = {
        'userId': userId,
        'deviceToken': deviceToken,
      };

      final repository = Repository(HttpService());
      final response = await repository.userVerifyWithDeviceToken(data);

      final result = jsonDecode(response.body);

      final success = response.statusCode == 200 && result['code'] == 200;

      setState(() {
        _isSucceed = success;
        _isLoading = false;
      });

      // if (success) {
      //   // Navigate based on role
      //   switch (role) {
      //     case UserRole.dealer:
      //       _navigateTo(DealerDashboard(
      //         userName: userName ?? "",
      //         countryCode: countryCode ?? "",
      //         mobileNo: "", // fetch from prefs if you have it
      //         userId: userId,
      //         emailId: email ?? "",
      //       ));
      //       break;
      //     case UserRole.subUser:
      //       _navigateTo(HomeScreen(userId: userId, fromDealer: false));
      //       break;
      //     case UserRole.customer:
      //       _navigateTo(HomeScreen(userId: userId, fromDealer: false));
      //       break;
      //     default:
      //       _navigateTo(const LoginScreen());
      //   }
      // } else {
      //   _navigateTo(const LoginScreen());
      // }
      _navigateTo(const LoginScreen());
    } catch (e, stackTrace) {
      print("Error in checkAuthentication: $e");
      print(stackTrace);
      _navigateTo(const LoginScreen());
    }
  }

  /// Helper to clean up navigation code
  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => page,
        transitionsBuilder: (context, animation1, animation2, child) {
          return FadeTransition(opacity: animation1, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

}