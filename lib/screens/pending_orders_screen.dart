import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PendingOrdersScreen extends StatefulWidget {
  final String token;
  final String role; // 👈 Add role parameter
  const PendingOrdersScreen(
      {super.key, required this.token, required this.role});

  @override
  State<PendingOrdersScreen> createState() => PendingOrdersScreenState();
}

class PendingOrdersScreenState extends State<PendingOrdersScreen> {
  List orders = [];
  List workers = [];
  bool loading = true;
  final baseUrl = dotenv.env['BASE_URL']!;

  @override
  void initState() {
    super.initState();
    fetchOrders();
    if (widget.role == 'provider') {
      fetchWorkers();
    }
  }

  Future<void> fetchOrders() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/orders/available'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('📝 Response status code: ${res.statusCode}');
      print('📝 Response headers: ${res.headers}');
      print('📝 Raw response body: ${res.body}');

      if (res.statusCode == 200) {
        final decodedData = jsonDecode(res.body);
        print('📝 Decoded data: $decodedData');

        setState(() {
          orders = decodedData;
          loading = false;
        });
      } else {
        print('❌ Error fetching orders: ${res.body}');
        print('❌ Status code: ${res.statusCode}');
        print('❌ Headers: ${res.headers}');
        setState(() {
          loading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Exception while fetching orders: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> fetchWorkers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/workers'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      setState(() {
        workers = jsonDecode(res.body);
      });
    } else {
      print('❌ Error fetching workers: ${res.body}');
    }
  }

  Future<void> assignToWorker(int orderId, int workerId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders/$orderId/assign'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'worker_id': workerId}),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Assigned successfully')),
      );
      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to assign')),
      );
    }
  }

  Future<void> acceptOrder(int orderId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders/$orderId/accept'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Order accepted')),
      );
      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to accept order')),
      );
    }
  }

  Future<void> updateStatus(int orderId, String status) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders/$orderId/status'),
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

  void _showContactOptions(String phoneNumber) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Call'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('WhatsApp'),
                onTap: () async {
                  Navigator.pop(context);
                  // Remove any non-numeric characters from the phone number
                  final cleanPhone =
                      phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
                  final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone');
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(whatsappUrl,
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${order['id']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text('💰 ${order['total'] ?? 0} AED',
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          const Divider(height: 20),
          Row(children: [
            const Icon(Icons.person, color: Colors.black54),
            const SizedBox(width: 8),
            Text(customer['name'] ?? 'N/A'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.phone, color: Colors.black54),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showContactOptions(customer['phone'] ?? ''),
              child: Text(
                customer['phone'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (order['car'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car_outlined,
                        color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order['car']['brand']['name']} ${order['car']['model']['name']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color:
                                      _getColorFromName(order['car']['color']),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                order['car']['color'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (order['car']['license_plate'] != null &&
                    order['car']['license_plate'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      'License Plate: ${order['car']['license_plate']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['address'] ?? 'N/A'),
                  if (latitude != null && longitude != null)
                    TextButton.icon(
                      onPressed: () => openMapsSheet(
                        latitude,
                        longitude,
                        'Customer Location #${order['id']}',
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
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.access_time_outlined, color: Colors.black54),
            const SizedBox(width: 8),
            Text(formatDateTime(order['created_at'])),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.cleaning_services_outlined, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(child: Text(services.map((s) => s['name']).join(', '))),
          ]),
          const SizedBox(height: 16),
          if (widget.role == 'provider')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    assignedUser != null
                        ? 'Assigned to: ${assignedUser['name']}'
                        : 'Not assigned yet',
                    style: TextStyle(
                      color: assignedUser != null ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  hint: const Text("Assign"),
                  value: null,
                  items: workers.map<DropdownMenuItem<int>>((worker) {
                    return DropdownMenuItem<int>(
                      value: worker['id'],
                      child: Text(worker['name']),
                    );
                  }).toList(),
                  onChanged: (workerId) {
                    if (workerId != null) assignToWorker(order['id'], workerId);
                  },
                ),
              ],
            ),
          if (widget.role == 'worker' || widget.role == 'provider')
            Align(
              alignment: Alignment.centerRight,
              child: order['status'] == 'pending'
                  ? ElevatedButton.icon(
                      onPressed: () => acceptOrder(order['id']),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : PopupMenuButton<String>(
                      onSelected: (value) => updateStatus(order['id'], value),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'in_progress', child: Text('🛠 Start')),
                        const PopupMenuItem(
                            value: 'completed', child: Text('✔ Finish')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child: const Text('Update'),
                      ),
                    ),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Available Orders',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  Color _getColorFromName(String colorName) {
    final Map<String, Color> colorMap = {
      'Black': Colors.black,
      'White': Colors.white,
      'Silver': Colors.grey.shade300,
      'Gray': Colors.grey,
      'Red': Colors.red,
      'Blue': Colors.blue,
      'Green': Colors.green,
      'Brown': Colors.brown,
      'Beige': const Color(0xFFF5F5DC),
      'Gold': const Color(0xFFFFD700),
    };

    return colorMap[colorName] ?? Colors.grey.shade400;
  }
}
