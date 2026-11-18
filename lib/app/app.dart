import'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/Constants/notifications_service.dart';
import 'package:oro_drip_irrigation/modules/IrrigationProgram/view/irrigation_program_main.dart';
import 'package:oro_drip_irrigation/modules/config_maker/view/config_base_page.dart';
import 'package:oro_drip_irrigation/modules/constant/view/constant_base_page.dart';
import 'package:oro_drip_irrigation/modules/irrigation_report/view/list_of_log_config.dart';
import 'package:oro_drip_irrigation/utils/Theme/agritel_theme.dart';
import '../Screens/login_screenOTP/login_screenotp.dart';
import '../flavors.dart';
import '../utils/Theme/smart_comm_theme.dart';
import '../utils/Theme/oro_theme.dart';
import '../utils/network_utils.dart';
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
     if(!kIsWeb){
      NotificationServiceCall().initialize();
      NotificationServiceCall().configureFirebaseMessaging();

     }
  }

  /// Decide the initial route based on whether a token exists
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

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: isOro ? OroTheme.lightTheme : isATel ? ATelTheme.lightTheme :
          SmartCommTheme.lightTheme,
          darkTheme: isOro ? OroTheme.darkTheme : isATel ? ATelTheme.darkTheme :
          SmartCommTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: navigateToInitialScreen(snapshot.data ?? Routes.login),
          onGenerateRoute: Routes.generateRoute,
          // home: const ConfigBasePage(masterData: {"userId":2,"customerId":16,"controllerId":2433,"productId":2429,"deviceId":"WEATHERTEST1","deviceName":"Weather (GSM)","categoryId":4,"categoryName":"ORO WEATHER","modelId":14,"modelDescription":"Weather (GSM)","modelName":"NAw1000GOOO","groupId":14,"groupName":"GREEN FIELDS","connectingObjectId":["25","29","30","31","32","33","34","35","36","37","38","39","-"],"productStock":[]}, fromDashboard: true),
        );
      },
    );
  }
}

/// Helper function to navigate to the appropriate screen
Widget navigateToInitialScreen(String route) {
  final isOro = F.appFlavor!.name.contains('oro');

  switch (route) {
    case Routes.login:
      return kIsWeb ? const LoginScreen() : isOro ? LoginScreenOTP() : const LoginScreen();
    case Routes.dashboard:
      return const ScreenController();
    default:
      return const SplashScreen();
  }
}