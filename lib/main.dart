import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:oro_drip_irrigation/modules/PumpController/state_management/pump_controller_provider.dart';
import 'package:oro_drip_irrigation/modules/bluetooth_low_energy/state_management/ble_service.dart';
import 'package:oro_drip_irrigation/providers/button_loading_provider.dart';
import 'package:oro_drip_irrigation/providers/user_provider.dart';
import 'package:oro_drip_irrigation/repository/repository.dart';
import 'package:oro_drip_irrigation/services/bluetooth/bluetooth_ble_service.dart';
import 'package:oro_drip_irrigation/services/bluetooth/bluetooth_classic_service.dart';
import 'package:oro_drip_irrigation/services/communication_service.dart';
import 'package:oro_drip_irrigation/services/http_service.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/utils/network_utils.dart';
import 'package:oro_drip_irrigation/view_models/admin_dealer/customer_search_view_model.dart';
import 'package:oro_drip_irrigation/view_models/customer/current_program_view_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'Constants/notifi_service.dart';
import 'StateManagement/customer_provider.dart';
import 'StateManagement/mqtt_payload_provider.dart';
import 'StateManagement/overall_use.dart';
import 'StateManagement/search_provider.dart';
import 'app/app.dart';
import 'firebase_options.dart';
import 'modules/IrrigationProgram/state_management/irrigation_program_provider.dart';
import 'modules/Preferences/state_management/preference_provider.dart';
import 'modules/SystemDefinitions/state_management/system_definition_provider.dart';
import 'modules/config_maker/state_management/config_maker_provider.dart';
import 'modules/constant/state_management/constant_provider.dart';

// Initialize local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler for Firebase
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

// Permissions request
Future<void> requestAppPermissions() async {
  debugPrint("Requesting permissions...");

  // Notifications (iOS + Android 13+)
  final notifStatus = await Permission.notification.request();
  debugPrint("Notification permission: $notifStatus");

  if (Platform.isAndroid) {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // better than generic .location
    ].request();

    debugPrint("BLE + Location permissions: $statuses");

    // Handle permanently denied
    if (notifStatus.isPermanentlyDenied ||
        statuses.values.any((s) => s.isPermanentlyDenied)) {
      await openAppSettings();
    }
  }
}

FutureOr<void> main() async {
  // CRITICAL: Initialize binding FIRST, before any other setup
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Now wrap everything in the same zone
  await runZonedGuarded(() async {
    // All initialization code goes HERE, inside the zone
    tz.initializeTimeZones();

    await NetworkUtils.initialize();
    // await dotenv.load(fileName: ".env.apikey");

    // Request runtime permissions before providers start
    if (!kIsWeb && Platform.isAndroid) {
      await requestAppPermissions();
    }

    // Firebase init
    if (!kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Firebase Messaging
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Local notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(initSettings);
      await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint("Notification tapped: ${details.payload}");
        },
      );

      // Background messaging
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          NotificationService().showNotification(
            title: message.notification!.title,
            body: message.notification!.body,
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("Message clicked: ${message.messageId}");
      });
    }

    // Run the app
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => CustomerProvider()),
          ChangeNotifierProvider(create: (_) => CustomerSearchViewModel()),
          ChangeNotifierProvider(create: (_) => ConfigMakerProvider()),
          ChangeNotifierProvider(
              create: (_) => IrrigationProgramMainProvider()),
          ChangeNotifierProvider(create: (_) => MqttPayloadProvider()),
          ChangeNotifierProvider(create: (_) => OverAllUse()),
          ChangeNotifierProvider(create: (_) => PreferenceProvider()),
          ChangeNotifierProvider(create: (_) => SystemDefinitionProvider()),
          ChangeNotifierProvider(create: (_) => ConstantProvider()),
          ChangeNotifierProvider(create: (_) => PumpControllerProvider()),
          ChangeNotifierProvider(create: (_) => BleProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => ButtonLoadingProvider()),
          ProxyProvider2<MqttPayloadProvider, CustomerProvider,
              CommunicationService>(
            update: (BuildContext context, MqttPayloadProvider mqttProvider,
                CustomerProvider customer, CommunicationService? previous) {
              return CommunicationService(
                mqttService: MqttService(),
                blueService: BluetoothClassicService(),
                bleService: BluetoothBleService(),
                customerProvider: customer,
              );
            },
          ),
          Provider<HttpService>(create: (_) => HttpService()),
          Provider<ApiRepository>(
            create: (context) => RepositoryImpl(context.read<HttpService>()),
          ),
          ChangeNotifierProvider(
            create: (context) => CurrentProgramViewModel(context, 0),
          ),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    print('Zone Error: $error');
    print('Stack: $stack');
  });
}
