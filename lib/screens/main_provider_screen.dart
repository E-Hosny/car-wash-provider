import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'pending_orders_screen.dart';
import 'accepted_orders_screen.dart';
import 'started_orders_screen.dart';
import 'completed_orders_screen.dart';

class MainProviderScreen extends StatefulWidget {
  final String token;
  const MainProviderScreen({super.key, required this.token});

  @override
  State<MainProviderScreen> createState() => _MainProviderScreenState();
}

class _MainProviderScreenState extends State<MainProviderScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // ⬇️ إرسال FCM Token للسيرفر
    FirebaseMessaging.instance.getToken().then((fcmToken) async {
      print("✅ FCM Token: $fcmToken");

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/fcm-token'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      print("🛰️ تم حفظ التوكن: ${response.body}");
    });

    // ⬇️ استقبال الإشعار أثناء فتح التطبيق (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📥 إشعار وصلك في Foreground:");
      print("🔔 Title: ${message.notification?.title}");
      print("📝 Body: ${message.notification?.body}");

      if (message.notification != null) {
        final notification = message.notification!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${notification.title} - ${notification.body}"),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      PendingOrdersScreen(token: widget.token),
      AcceptedOrdersScreen(token: widget.token),
      StartedOrdersScreen(token: widget.token),
      CompletedOrdersScreen(token: widget.token),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Pending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Accepted',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow_outlined),
            label: 'Started',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Completed',
          ),
        ],
      ),
    );
  }
}
