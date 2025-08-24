import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:car_wash_provider/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Tests', () {
    setUpAll(() async {
      // تهيئة SharedPreferences للاختبارات
      const MethodChannel('plugins.flutter.io/shared_preferences')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{}; // إرجاع قائمة فارغة
        }
        return null;
      });
    });

    test('should handle empty token correctly', () async {
      // اختبار التعامل مع التوكن الفارغ
      final isLoggedIn = await AuthService.isLoggedIn();
      expect(isLoggedIn, false);
    });

    test('should return null for non-existent data', () async {
      // اختبار إرجاع null للبيانات غير الموجودة
      final token = await AuthService.getToken();
      final email = await AuthService.getUserEmail();
      final role = await AuthService.getUserRole();

      expect(token, null);
      expect(email, null);
      expect(role, null);
    });
  });
}
