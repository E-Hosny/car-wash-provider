import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CompletedOrdersScreen extends StatefulWidget {
  final String token;
  final String role; // ✅ أضفنا نوع المستخدم
  const CompletedOrdersScreen(
      {super.key, required this.token, required this.role});

  @override
  State<CompletedOrdersScreen> createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/orders/completed'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      setState(() {
        orders = jsonDecode(res.body);
        loading = false;
      });
    } else {
      print('❌ Error fetching completed orders: ${res.body}');
    }
  }

  String formatDateTime(String? datetime) {
    if (datetime == null) return 'N/A';
    final dt = DateTime.tryParse(datetime)?.toLocal();
    if (dt == null) return 'N/A';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Completed Orders',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(
                  child: Text(
                    "No completed orders.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final customer = order['customer'];
                    final services = order['services'] as List;
                    final assignedUser = order['assigned_user'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
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
                                const Icon(Icons.location_on_outlined,
                                    color: Colors.black54),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(order['address'] ?? 'N/A',
                                      style: const TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Date
                            Row(
                              children: [
                                const Icon(Icons.access_time_outlined,
                                    color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  formatDateTime(order['created_at']),
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.black87),
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

                            // Assigned to (for provider)
                            if (widget.role == 'provider')
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
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
                                        color: assignedUser != null
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Completed at
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  'Completed at: ${formatDateTime(order['updated_at'])}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
