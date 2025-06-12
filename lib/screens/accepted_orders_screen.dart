import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:map_launcher/map_launcher.dart';

class AcceptedOrdersScreen extends StatefulWidget {
  final String token;
  final String role; // ✅ أضفنا role هنا
  const AcceptedOrdersScreen(
      {super.key, required this.token, required this.role});

  @override
  State<AcceptedOrdersScreen> createState() => _AcceptedOrdersScreenState();
}

class _AcceptedOrdersScreenState extends State<AcceptedOrdersScreen> {
  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/orders/accepted'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      setState(() {
        orders = jsonDecode(res.body);
        loading = false;
      });
    } else {
      print('❌ Error fetching accepted orders: ${res.body}');
    }
  }

  Future<void> updateStatus(int orderId, String status) async {
    final res = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/orders/$orderId/status'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? '✅ Status updated')),
      );
      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to update status')),
      );
    }
  }

  Future<void> openMapsSheet(
      double latitude, double longitude, String orderId) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Choose Maps App',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        for (var map in availableMaps)
                          ListTile(
                            onTap: () {
                              map.showMarker(
                                coords: Coords(latitude, longitude),
                                title: 'Customer Location #$orderId',
                              );
                              Navigator.pop(context);
                            },
                            title: Text(map.mapName),
                            leading: const Icon(Icons.map_outlined),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('❌ Error opening maps: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error opening maps')),
      );
    }
  }

  String formatDateTime(String? datetime) {
    if (datetime == null) return 'N/A';
    final dt = DateTime.tryParse(datetime)?.toLocal();
    if (dt == null) return 'N/A';

    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget buildOrderCard(order) {
    final customer = order['customer'];
    final services = order['services'] as List;
    final assignedUser = order['assigned_user'];

    // Safe conversion of latitude and longitude
    final latitude = order['latitude'] != null
        ? double.tryParse(order['latitude'].toString())
        : null;
    final longitude = order['longitude'] != null
        ? double.tryParse(order['longitude'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID + Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '💰 ${order['total']} SAR',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Customer
            Row(
              children: [
                const Icon(Icons.person, color: Colors.black54),
                const SizedBox(width: 8),
                Text(customer['name'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),

            // Phone
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.black54),
                const SizedBox(width: 8),
                Text(customer['phone'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),

            // Car
            if (order['car'] != null)
              Row(
                children: [
                  const Icon(Icons.directions_car_outlined,
                      color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    '${order['car']['brand']['name']} ${order['car']['model']['name']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            const SizedBox(height: 10),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['address'] ?? 'N/A',
                          style: const TextStyle(fontSize: 16)),
                      if (latitude != null && longitude != null)
                        TextButton.icon(
                          onPressed: () => openMapsSheet(
                            latitude,
                            longitude,
                            order['id'].toString(),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open in Maps'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerRight,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Date
            Row(
              children: [
                const Icon(Icons.access_time_outlined, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  formatDateTime(order['created_at']),
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Services
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cleaning_services_outlined,
                    color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    services.map((s) => s['name']).join(', '),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Assigned to
            if (widget.role == 'provider')
              Row(
                children: [
                  const Icon(Icons.person_pin_circle_outlined,
                      color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    assignedUser != null
                        ? 'Assigned to: ${assignedUser['name']}'
                        : 'Not assigned yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: assignedUser != null ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Update status
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                onSelected: (value) => updateStatus(order['id'], value),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'in_progress', child: Text('🛠 Start')),
                  const PopupMenuItem(
                      value: 'completed', child: Text('✔ Complete')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: const Text(
                    'Update Status',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Accepted Orders',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return buildOrderCard(orders[index]);
              },
            ),
    );
  }
}
