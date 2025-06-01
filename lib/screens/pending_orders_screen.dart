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
      setState(() {
        orders = jsonDecode(res.body);
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
            // الحالة + السعر
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
                  '💰 ${order['total'] ?? 0} SAR',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // الاسم
            Row(
              children: [
                const Icon(Icons.person, color: Colors.black54),
                const SizedBox(width: 8),
                Text(customer['name'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),

            // الهاتف
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.black54),
                const SizedBox(width: 8),
                Text(customer['phone'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),

            // العنوان
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order['address'] ?? 'N/A',
                      style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // الوقت
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

            // الخدمات
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

            const SizedBox(height: 16),

            // زر القبول أو التحديث
            Align(
              alignment: Alignment.centerRight,
              child: order['status'] == 'pending'
                  ? ElevatedButton.icon(
                      onPressed: () => acceptOrder(order['id']),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Accept Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  : PopupMenuButton<String>(
                      onSelected: (value) => updateStatus(order['id'], value),
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
          'Pending Orders',
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
