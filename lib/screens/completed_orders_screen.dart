import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CompletedOrdersScreen extends StatefulWidget {
  final String token;
  final String role; // ✅ أضفنا نوع المستخدم
  const CompletedOrdersScreen(
      {super.key, required this.token, required this.role});

  @override
  State<CompletedOrdersScreen> createState() => CompletedOrdersScreenState();
}

class CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  List orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final baseUrl = dotenv.env['BASE_URL']!;
    final res = await http.get(
      Uri.parse('$baseUrl/api/orders/completed'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      setState(() {
        // Sort orders by created_at in descending order (newest first)
        orders = List.from(jsonDecode(res.body));
        orders.sort((a, b) {
          final aDate = DateTime.tryParse(a['created_at'] ?? '');
          final bDate = DateTime.tryParse(b['created_at'] ?? '');
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // Descending order
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Completed Orders',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

                    // Multi-car order handling
                    final bool isMultiCar = order['is_multi_car'] ?? false;
                    final allCars = order['all_cars'] ?? [];

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
                                Row(
                                  children: [
                                    Text(
                                      'Order #${order['id']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (isMultiCar) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Multi',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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
                                GestureDetector(
                                  onTap: () => _showContactOptions(
                                      customer['phone'] ?? ''),
                                  child: Text(
                                    customer['phone'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Car
                            if (isMultiCar && allCars.isNotEmpty) ...[
                              // عرض السيارات المتعددة
                              Row(
                                children: [
                                  const Icon(Icons.directions_car_outlined,
                                      color: Colors.black54),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cars: ${order['cars_count'] ?? allCars.length} vehicles',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // تفاصيل كل سيارة
                              for (int i = 0; i < allCars.length; i++) ...[
                                _buildMultiCarDetail(allCars[i], i),
                              ]
                            ] else if (order['car'] != null) ...[
                              // عرض السيارة الواحدة (النظام القديم)
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${order['car']['brand']['name']} ${order['car']['model']['name']}',
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: _getColorFromName(
                                                        order['car']['color']),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
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
                                      order['car']['license_plate']
                                          .toString()
                                          .isNotEmpty)
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
                            ],
                            const SizedBox(height: 10),

                            // Address
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    color: Colors.black54),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if ((order['street'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text('Street: ${order['street']}',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      if ((order['building'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text('Building: ${order['building']}',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      if ((order['floor'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text('Floor: ${order['floor']}',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      if ((order['apartment'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text('Apartment: ${order['apartment']}',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      Text(order['address'] ?? 'N/A',
                                          style: const TextStyle(fontSize: 16)),
                                    ],
                                  ),
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

  String _getCarDisplayName(dynamic carData) {
    try {
      if (carData == null) return 'Unknown Car';

      // Handle both old format (object with brand/model) and new format (direct strings)
      if (carData['brand'] != null && carData['model'] != null) {
        final brandName = carData['brand']['name'] ?? carData['brand'];
        final modelName = carData['model']['name'] ?? carData['model'];
        return '$brandName $modelName';
      } else if (carData['brand'] != null) {
        return carData['brand'].toString();
      } else if (carData['model'] != null) {
        return carData['model'].toString();
      } else {
        return 'Unknown Car';
      }
    } catch (e) {
      return 'Car data error';
    }
  }

  String _getServicesDisplayText(List servicesList) {
    try {
      if (servicesList.isEmpty) return 'No services';

      final serviceNames = servicesList
          .map((s) {
            // Handle both old format (object with name) and new format (direct string)
            if (s is Map && s['name'] != null) {
              return s['name'].toString();
            } else if (s is String) {
              return s;
            } else {
              return 'Unknown Service';
            }
          })
          .where((name) => name.isNotEmpty)
          .toList();

      return serviceNames.isNotEmpty
          ? serviceNames.join(' • ')
          : 'No valid services';
    } catch (e) {
      return 'Services data error';
    }
  }

  Widget _buildMultiCarDetail(dynamic carDetail, int carIndex) {
    try {
      final carData = carDetail; // The car data is directly in carDetail
      final carServices =
          carDetail != null ? (carDetail['services'] ?? []) : [];

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚗 Car ${carIndex + 1}: ${_getCarDisplayName(carData)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              '🔧 Services: ${_getServicesDisplayText(carServices)}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          '❌ Error displaying car ${carIndex + 1}',
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }
  }
}
