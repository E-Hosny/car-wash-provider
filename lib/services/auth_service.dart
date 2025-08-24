import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  // حفظ بيانات المستخدم بعد تسجيل الدخول
  static Future<void> saveUserData({
    required String token,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userRoleKey, role);
  }

  // التحقق من وجود توكن صالح
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  // استرجاع التوكن المحفوظ
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // استرجاع البريد الإلكتروني المحفوظ
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // استرجاع دور المستخدم المحفوظ
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // حذف جميع بيانات المستخدم (تسجيل الخروج)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
  }

  // التحقق من صلاحية التوكن
  static Future<bool> isTokenValid(String token) async {
    // يمكن إضافة منطق للتحقق من صلاحية التوكن هنا
    // مثل إرسال طلب للخادم للتحقق من صلاحية التوكن
    return token.isNotEmpty;
  }
}
