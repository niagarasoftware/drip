import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/Constants/notifications_service.dart';
import 'package:oro_drip_irrigation/utils/Theme/agritel_theme.dart';

import '../Screens/login_screenOTP/login_screenotp.dart';
import '../flavors.dart';
import '../utils/Theme/oro_theme.dart';
import '../utils/Theme/smart_comm_theme.dart';
import '../utils/routes.dart';
import '../utils/shared_preferences_helper.dart';
import '../views/common/login/login_screen.dart';
import '../views/screen_controller.dart';
import '../views/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      NotificationServiceCall().initialize();
      NotificationServiceCall().configureFirebaseMessaging();
    }
  }

  Future<String> getInitialRoute() async {
    try {
      final token = await PreferenceHelper.getToken();

      if (token != null && token.trim().isNotEmpty) {
        return Routes.dashboard;
      } else {
        return Routes.login;
      }
    } catch (e) {
      print("Error in getInitialRoute: $e");
      return Routes.login;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Flavor is: ${F.appFlavor}');

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return FutureBuilder<String>(
      future: getInitialRoute(),
      builder: (context, snapshot) {
        var isOro = F.appFlavor?.name.contains('oro') ?? false;
        var isATel = F.appFlavor?.name.contains('agritel') ?? false;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        }

        final initialRoute = snapshot.data ?? Routes.login;

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,

          theme: isOro
              ? OroTheme.lightTheme
              : isATel
              ? ATelTheme.lightTheme
              : SmartCommTheme.lightTheme,

          darkTheme: isOro
              ? OroTheme.darkTheme
              : isATel
              ? ATelTheme.darkTheme
              : SmartCommTheme.darkTheme,

          themeMode: ThemeMode.light,

          home: navigateToInitialScreen(initialRoute),

          onGenerateRoute: Routes.generateRoute,
        );
      },
    );
  }
}

Widget navigateToInitialScreen(String route) {
  final isOro = F.appFlavor?.name.contains('oro') ?? false;

  switch (route) {
    case Routes.login:
      return kIsWeb
          ? const LoginScreen()
          : isOro
              ? const LoginScreenOTP()
              : const LoginScreen();

    case Routes.dashboard:
      return const ScreenController();

    default:
      return const SplashScreen();
  }
}
