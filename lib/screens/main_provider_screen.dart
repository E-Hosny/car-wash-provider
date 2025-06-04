import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  String? role;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/user'),
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

  @override
  Widget build(BuildContext context) {
    if (loading || role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      PendingOrdersScreen(token: widget.token, role: role!), // ✅ role sent here
      AcceptedOrdersScreen(token: widget.token, role: role!),
      StartedOrdersScreen(token: widget.token, role: role!),
      CompletedOrdersScreen(token: widget.token, role: role!),
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
              icon: Icon(Icons.assignment), label: 'Pending'),
          BottomNavigationBarItem(
              icon: Icon(Icons.work_outline), label: 'Accepted'),
          BottomNavigationBarItem(
              icon: Icon(Icons.play_arrow_outlined), label: 'Started'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle), label: 'Completed'),
        ],
      ),
    );
  }
}
