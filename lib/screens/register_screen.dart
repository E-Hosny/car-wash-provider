import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? nameError;
  String? phoneError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? generalError;

  Future<void> register() async {
    setState(() {
      nameError = phoneError = emailError =
          passwordError = confirmPasswordError = generalError = null;
    });

    final baseUrl = dotenv.env['BASE_URL']!;
    final url = Uri.parse('$baseUrl/api/register');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({
        'name': nameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'password_confirmation': confirmPasswordController.text,
        'role': 'provider',
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Registration successful')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (response.statusCode == 422) {
      final errors = body['errors'] ?? {};
      setState(() {
        nameError = errors['name']?.first;
        phoneError = errors['phone']?.first;
        emailError = errors['email']?.first;
        passwordError = errors['password']?.first;
        confirmPasswordError = errors['password_confirmation']?.first;
        generalError = body['message'];
      });
    } else {
      setState(() {
        generalError = '❌ Registration failed. Please try again.';
      });
    }
  }

  Widget buildTextField({
    required String label,
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
          'Provider Registration',
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
            Image.asset(
              'assets/logo.png',
              height: 250,
              width: 250,
            ),
            const SizedBox(height: 30),
            buildTextField(
              label: 'Full Name',
              controller: nameController,
              errorText: nameError,
            ),
            const SizedBox(height: 14),
            buildTextField(
              label: 'Phone',
              controller: phoneController,
              keyboardType: TextInputType.phone,
              errorText: phoneError,
            ),
            const SizedBox(height: 14),
            buildTextField(
              label: 'Email',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: emailError,
            ),
            const SizedBox(height: 14),
            buildTextField(
              label: 'Password',
              controller: passwordController,
              obscure: true,
              errorText: passwordError,
            ),
            const SizedBox(height: 14),
            buildTextField(
              label: 'Confirm Password',
              controller: confirmPasswordController,
              obscure: true,
              errorText: confirmPasswordError,
            ),
            const SizedBox(height: 24),
            if (generalError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  generalError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: register,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Register',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
