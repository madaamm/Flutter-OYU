import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://oyu-learnkz.onrender.com/api';

  // ✅ ScenarioSelectScreen 1-ақ рет көрсету (әр email-ға бөлек)
  static String _scenarioKey(String email) =>
      'scenario_shown_${email.trim().toLowerCase()}';

  Future<bool> isScenarioShownForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_scenarioKey(email)) ?? false;
  }

  Future<void> setScenarioShownForEmail(String email, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scenarioKey(email), value);
  }

  // ================= TOKEN / ROLE =================

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
  Future<Map<String, dynamic>> me() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token жоқ (сақталмаған).');
    }

    final uri = Uri.parse('$baseUrl/user/me');

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));

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
    // ❗ Scenario флагтарын өшірмейміз (1 рет көрсетілу шарты бұзылмасын)
  }
}