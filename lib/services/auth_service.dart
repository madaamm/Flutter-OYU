import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://oyu-learnkz.onrender.com/api';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  /// ✅ GET /user/me (Bearer token)
  /// Егер token жоқ/бос болса немесе сервер 200 қайтармаса — Exception лақтырады.
  Future<Map<String, dynamic>> me() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token жоқ (сақталмаған).');
    }

    final uri = Uri.parse('$baseUrl/user/me');

    final res = await http
        .get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('ME error ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;

    throw Exception('ME response дұрыс емес: ${res.body}');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
  }
}
