import 'dart:async';
import 'package:flutter/material.dart';
import 'package:car_wash_provider/services/auth_service.dart';
import 'package:car_wash_provider/services/token_validation_service.dart';
import 'login_screen.dart';
import 'main_provider_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // لإظهار اللوغو قليلاً

    if (!mounted) return;

    // التحقق من حالة تسجيل الدخول
    final isLoggedIn = await AuthService.isLoggedIn();

    if (isLoggedIn) {
      final token = await AuthService.getToken();
      if (token != null) {
        // التحقق من صلاحية التوكن مع الخادم
        final isTokenValid =
            await TokenValidationService.isTokenStillValid(token);

        if (isTokenValid && mounted) {
          // التوكن صالح، انتقل إلى الشاشة الرئيسية
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainProviderScreen(token: token)),
          );
          return;
        } else {
          // التوكن غير صالح، احذفه وانتقل إلى تسجيل الدخول
          await AuthService.clearUserData();
        }
      }
    }

    // إذا لم يكن هناك تسجيل دخول صالح، انتقل إلى شاشة تسجيل الدخول
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo.png', // تأكد إن الصورة موجودة فعلاً في المسار
          width: 200,
        ),
      ),
    );
  }
}
