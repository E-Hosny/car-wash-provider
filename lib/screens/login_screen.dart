import 'dart:convert';
import 'package:car_wash_provider/notification_service.dart';
import 'package:car_wash_provider/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'register_screen.dart';
import 'main_provider_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? emailError;
  String? passwordError;
  String? generalError;
  bool loading = false;

  final baseUrl = dotenv.env['BASE_URL']!;

  Future<void> uploadFcmToken(String token, String fcmToken) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/fcm/save-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': fcmToken}),
      );
    } catch (e) {
      print('❌ Error uploading FCM token: $e');
    }
  }

  Future<void> login() async {
    setState(() {
      emailError = null;
      passwordError = null;
      generalError = null;
      loading = true;
    });

    print('🟢 BASE_URL: ' + baseUrl);
    print('🟢 Login URL: ' + Uri.parse('$baseUrl/api/login').toString());
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'role': 'provider',
      }),
    );
    setState(() {
      loading = false;
    });
    if (!mounted) return;
    if (response.statusCode == 200) {
      print('🔵 statusCode: ${response.statusCode}');
      print('🔵 response.body: ${response.body}');
      try {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userRole = data['user']?['role'] ?? 'provider';
        final userEmail = emailController.text.trim();

        // حفظ بيانات المستخدم محلياً
        await AuthService.saveUserData(
          token: token,
          email: userEmail,
          role: userRole,
        );

        final fcmToken = await NotificationService.getFCMToken();
        print('FCM Token: ' + (fcmToken ?? 'NULL'));
        if (fcmToken != null) {
          await uploadFcmToken(token, fcmToken);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم تسجيل الدخول بنجاح')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainProviderScreen(token: token)),
        );
      } catch (e) {
        print('❌ JSON decode error: ${e.toString()}');
        setState(() {
          generalError = '❌ Unexpected response format (200): ' + e.toString();
        });
      }
    } else {
      print('🔴 statusCode: ${response.statusCode}');
      print('🔴 response.body: ${response.body}');
      try {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
          setState(() {
            emailError = data['errors']['email']?.first;
            passwordError = data['errors']['password']?.first;
          });
        } else if (data['message'] != null) {
          setState(() {
            generalError = data['message'];
          });
        } else {
          setState(() {
            generalError = '❌ Unexpected error occurred';
          });
        }
      } catch (e) {
        print('❌ JSON decode error: ${e.toString()}');
        setState(() {
          generalError = '❌ Unexpected response format: ' + e.toString();
        });
      }
    }
  }

  Widget buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? errorText,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: Icon(icon, color: Colors.black),
        labelStyle: const TextStyle(color: Colors.black87),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black, width: 1.4),
          borderRadius: BorderRadius.circular(12),
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
          'Provider Login',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Image.asset('assets/logo.png', height: 250, width: 250),
            const SizedBox(height: 30),
            buildTextField(
              label: 'Email',
              icon: Icons.email,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: emailError,
            ),
            const SizedBox(height: 16),
            buildTextField(
              label: 'Password',
              icon: Icons.lock,
              controller: passwordController,
              obscure: true,
              errorText: passwordError,
            ),
            const SizedBox(height: 20),
            if (generalError != null)
              Text(
                generalError!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: loading ? null : login,
                icon: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  loading ? 'Logging in...' : 'Login',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            // const SizedBox(height: 16),
            // TextButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const RegisterScreen()),
            //     );
            //   },
            //   child: const Text(
            //     'Don\'t have an account? Register here',
            //     style: TextStyle(color: Colors.black54),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
