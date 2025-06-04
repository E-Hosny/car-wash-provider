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

  @override
  void initState() {
    super.initState();
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
