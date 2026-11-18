import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notifi_service.dart';
import 'package:oro_drip_irrigation/utils/helpers/log_print.dart';


class NotificationServiceCall {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


  Future<void> initialize() async {

    // Request notification permissions
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    }

    // Request permission for iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and store FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deviceToken', token);
      debugPrint('FCM Token: $token');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        NotificationService().showNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Handle background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Assuming you have access to a navigator key or context
        // You might need to modify this based on your navigation setup
      }
    });

    // Handle initial message when app is launched from notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && initialMessage.notification != null) {
      // Handle navigation if needed
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Handle background messages if needed
  }

  void configureFirebaseMessaging() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLog.log('Foreground message received: ${message.messageId}');
      if (message.notification != null) {
        _showNotification({
          'notification': {
            'title': message.notification?.title ?? 'Notification',
            'body': message.notification?.body ?? 'New notification received',
          },
          'data': message.data,
        });
      }
    });

    // Handle notifications when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLog.log('Message opened app: ${message.messageId}');
      _navigateToScreen({
        'notification': {
          'title': message.notification?.title,
          'body': message.notification?.body,
        },
        'data': message.data,
      });
    });

    // Handle initial message when the app is launched from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        AppLog.log('Initial message: ${message.messageId}');
        _navigateToScreen({
          'notification': {
            'title': message.notification?.title,
            'body': message.notification?.body,
          },
          'data': message.data,
        });
      }
    });

  }

  Future<void> _showNotification(Map<String, dynamic> notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'oro_channel_id',
      'Oro Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      notification['notification']['title'] ?? 'Notification',
      notification['notification']['body'] ?? 'You have a new notification',
       platformChannelSpecifics,
      payload: notification['data']?.toString(),
    );
  }
  void _navigateToScreen(Map<String, dynamic> notification) {
    // Implement navigation logic based on notification data
    AppLog.log('Navigate based on: $notification');
    // Example: Navigate to a specific screen if notification contains a route
    // if (notification['data']['route'] != null) {
    //   Navigator.pushNamed(context, notification['data']['route']);
    // }
  }


}