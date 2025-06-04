import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PendingOrdersScreen extends StatefulWidget {
  final String token;
  final String role; // 👈 Add role parameter
  const PendingOrdersScreen(
      {super.key, required this.token, required this.role});

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  List orders = [];
  List workers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
    if (widget.role == 'provider') {
      fetchWorkers();
    }
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

  Future<void> fetchWorkers() async {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/workers'),
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
      Uri.parse('http://10.0.2.2:8000/api/orders/$orderId/assign'),
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
    final assignedUser = order['assigned_user'];

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
              Text('💰 ${order['total'] ?? 0} SAR',
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
            Text(customer['phone'] ?? 'N/A'),
          ]),
          const SizedBox(height: 10),
          if (order['car'] != null)
            Row(children: [
              const Icon(Icons.directions_car_outlined, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                  '${order['car']['brand']['name']} ${order['car']['model']['name']}'),
            ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(child: Text(order['address'] ?? 'N/A')),
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
                Text(
                  assignedUser != null
                      ? 'Assigned to: ${assignedUser['name']}'
                      : 'Not assigned yet',
                  style: TextStyle(
                    color: assignedUser != null ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<int>(
                  hint: const Text("Assign to"),
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
                      label: const Text('Accept Order'),
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
                            value: 'completed', child: Text('✔ Complete')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child: const Text('Update Status'),
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
        title: const Text('Pending Orders',
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
}
