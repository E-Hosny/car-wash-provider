import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PendingOrdersScreen extends StatefulWidget {
  final String token;
  const PendingOrdersScreen({super.key, required this.token});

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/orders/available'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      setState(() {
        orders = decoded;
        loading = false;
      });
    } else {
      print('❌ Error fetching orders: ${res.body}');
    }
  }

  Future<void> acceptOrder(int orderId) async {
    final res = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/orders/$orderId/accept'),
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
      print('❌ Accept error: ${res.body}');
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
      print('❌ Error updating status: ${res.body}');
    }
  }

  Widget buildStatusBadge(String status) {
    Color bgColor;
    switch (status) {
      case 'completed':
        bgColor = Colors.green.shade100;
        break;
      case 'in_progress':
        bgColor = Colors.orange.shade100;
        break;
      case 'accepted':
        bgColor = Colors.blue.shade100;
        break;
      default:
        bgColor = Colors.grey.shade300;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '📌 Status: $status',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final customer = order['customer'];
        final services = order['services'] as List;

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📦 Order #${order['id']}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Text('👤 Customer: ${customer['name']}'),
                Text('📱 Phone: ${customer['phone']}'),
                Text('📍 Address: ${order['address'] ?? 'N/A'}'),
                Text(
                    '🕒 Date: ${order['created_at'].toString().substring(0, 16)}'),
                const SizedBox(height: 6),
                buildStatusBadge(order['status']),
                const SizedBox(height: 10),
                const Text('🧼 Services:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...services.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('- ${s['name']} (${s['price']} SAR)'),
                    )),
                const SizedBox(height: 8),
                Text(
                  '💰 Total: ${order['total']} SAR',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                /// إما زر Accept أو زر تغيير الحالة
                Align(
                  alignment: Alignment.centerRight,
                  child: order['status'] == 'pending'
                      ? ElevatedButton(
                          onPressed: () => acceptOrder(order['id']),
                          child: const Text('✅ Accept Order'),
                        )
                      : PopupMenuButton<String>(
                          onSelected: (value) =>
                              updateStatus(order['id'], value),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'in_progress', child: Text('🛠 Start')),
                            const PopupMenuItem(
                                value: 'completed', child: Text('✔ Complete')),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.blue.shade50,
                            ),
                            child: const Text('Update Status',
                                style: TextStyle(color: Colors.blue)),
                          ),
                        ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
