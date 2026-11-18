import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oro_drip_irrigation/Screens/login_screenOTP/login_screenotp.dart';
import '../views/screen_controller.dart';
import '../views/common/login/login_screen.dart';
import '../views/splash_screen.dart';

class Routes {
  static const String flash = '/';
  static const String login = '/login';
  static const String loginOtp = '/loginOtp';
  static const String dashboard = '/dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.flash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case Routes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case Routes.loginOtp:
        return MaterialPageRoute(
          builder: (_) =>  LoginScreenOTP(),
          settings: settings,
        );
      case Routes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const ScreenController(),
          settings: settings,
        );
      default:
     return isSkiaWeb ?   MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Unknown Route')),
          ),
          settings: settings,
        ) :  MaterialPageRoute(
          builder: (_) =>  LoginScreenOTP(),
    settings: settings,
    ) ;
    }
  }
}