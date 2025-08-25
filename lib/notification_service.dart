import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      print('🔥 Initializing Firebase...');
      await Firebase.initializeApp();
      print('✅ Firebase initialized successfully');

      print('🔔 Requesting notification permissions...');
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('📱 User notification settings:');
      print('- Authorization status: ${settings.authorizationStatus}');
      print('- Alert setting: ${settings.alert}');
      print('- Sound setting: ${settings.sound}');
      print('- Badge setting: ${settings.badge}');

      print('🎵 Setting up local notifications...');

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
      print('✅ Local notifications initialized');

      print('👂 Setting up message handlers...');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Got a message whilst in the foreground!');
        print('- Message data: ${message.data}');
        print(
            '- Notification: ${message.notification?.title} - ${message.notification?.body}');

        if (message.notification != null) {
          _showNotification(message.notification!);
        }
      });
      print('✅ Message handlers set up');

      // Get the token and print it
      final token = await getFCMToken();
      print('📱 FCM Token: $token');
    } catch (e, stackTrace) {
      print('❌ Error initializing notifications:');
      print('- Error: $e');
      print('- Stack trace: $stackTrace');
    }
  }

  static Future<String?> getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      print('📱 Got FCM token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  static void _showNotification(RemoteNotification notification) async {
    try {
      print('🔔 Showing local notification:');
      print('- Title: ${notification.title}');
      print('- Body: ${notification.body}');

      // Android notification details
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );

      // iOS notification details
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
      );
      print('✅ Local notification shown successfully');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }
}
