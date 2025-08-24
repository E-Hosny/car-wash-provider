import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:car_wash_provider/services/auth_service.dart';

import 'pending_orders_screen.dart';
import 'accepted_orders_screen.dart';
import 'started_orders_screen.dart';
import 'completed_orders_screen.dart';
import 'login_screen.dart';

class MainProviderScreen extends StatefulWidget {
  final String token;
  const MainProviderScreen({super.key, required this.token});

  @override
  State<MainProviderScreen> createState() => _MainProviderScreenState();
}

class _MainProviderScreenState extends State<MainProviderScreen> {
  int _currentIndex = 0;
  String? role;
  bool loading = true;

  // GlobalKeys for each screen
  final _pendingKey = GlobalKey<PendingOrdersScreenState>();
  final _acceptedKey = GlobalKey<AcceptedOrdersScreenState>();
  final _startedKey = GlobalKey<StartedOrdersScreenState>();
  final _completedKey = GlobalKey<CompletedOrdersScreenState>();

  // 🔔 Notification Plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final baseUrl = dotenv.env['BASE_URL']!;

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    setupFCMListeners();
    requestNotificationPermission();
  }

  // 🟡 إعداد FCM
  void setupFCMListeners() async {
    // إعداد الإشعارات المحلية
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // عند وصول إشعار والتطبيق مفتوح
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'تنبيهات الطلبات',
              channelDescription: 'لإشعارات الطلبات الجديدة',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
        );
      }
    });
  }

  Future<void> fetchUserRole() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/user'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final userData = jsonDecode(res.body);
      setState(() {
        role = userData['role'];
        loading = false;
      });
    } else {
      print("❌ Failed to fetch user role");
      setState(() {
        role = null;
        loading = false;
      });
    }
  }

  // 🟢 طلب صلاحية الإشعارات بشكل متوافق مع كل الأنظمة
  Future<void> requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تنبيه'),
            content: const Text(
                'يرجى تفعيل صلاحية الإشعارات من إعدادات النظام حتى تصلك التنبيهات.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('حسنًا'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Re-initialize the screens list on every build to ensure they are fresh
    final List<Widget> screens = [
      PendingOrdersScreen(token: widget.token, role: role!),
      AcceptedOrdersScreen(token: widget.token, role: role!),
      StartedOrdersScreen(token: widget.token, role: role!),
      CompletedOrdersScreen(token: widget.token, role: role!),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              // حذف جميع بيانات المستخدم
              await AuthService.clearUserData();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body:
          screens[_currentIndex], // Use direct indexing instead of IndexedStack
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Available',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Accepted',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run_outlined),
            label: 'In Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_outlined),
            label: 'Completed',
          ),
        ],
      ),
    );
  }
}
