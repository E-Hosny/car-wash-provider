import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TokenValidationService {
  static final String baseUrl = dotenv.env['BASE_URL']!;

  // التحقق من صلاحية التوكن مع الخادم
  static Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        // التحقق من أن الاستجابة تحتوي على بيانات المستخدم
        return userData['id'] != null && userData['email'] != null;
      }

      return false;
    } catch (e) {
      print('❌ Error validating token: $e');
      return false;
    }
  }

  // التحقق من أن التوكن لا يزال صالحاً
  static Future<bool> isTokenStillValid(String token) async {
    if (token.isEmpty) return false;

    try {
      final isValid = await validateToken(token);
      return isValid;
    } catch (e) {
      print('❌ Error checking token validity: $e');
      return false;
    }
  }
}
