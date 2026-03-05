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

  // ================= USER ID CACHE ✅ =================

  Future<void> saveUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // ================= NICKNAME CACHE (per user) ✅ =================

  String _nickKey(int userId) => 'nickname_u_$userId';

  Future<void> saveNicknameForUser(int userId, String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nickKey(userId), nickname);
  }

  Future<String?> getNicknameForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nickKey(userId));
  }

  // ================= USERNAME CACHE (per user) ✅ NEW =================

  String _usernameKey(int userId) => 'username_u_$userId';

  Future<void> saveUsernameForUser(int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey(userId), username);
  }

  Future<String?> getUsernameForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey(userId));
  }

  /// ✅ HomeScreen үшін: кештен атын алып береді
  Future<String> getCachedUsernameOrDefault() async {
    final userId = await getUserId();
    if (userId == null) return 'User';

    final name = await getUsernameForUser(userId);
    if (name == null || name.trim().isEmpty) return 'User';

    return name.trim();
  }

  // ================= ME =================

  /// ✅ GET /user/me (Bearer token)
  /// + username кешке автомат түседі (HomeScreen автомат оқиды)
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

    if (decoded is Map<String, dynamic>) {
      // ✅ username кешке түсіру
      final userId = await getUserId();
      if (userId != null) {
        final username =
        (decoded['username'] ?? decoded['user']?['username'] ?? '').toString();
        if (username.trim().isNotEmpty) {
          await saveUsernameForUser(userId, username.trim());
        }
      }
      return decoded;
    }

    throw Exception('ME response дұрыс емес: ${res.body}');
  }

  // ================= PATCH username ✅ NEW =================

  /// ✅ PATCH /user/me/username
  /// body: {"username": "NewName"}
  /// Success болса username_u_<userId> жаңарады
  Future<Map<String, dynamic>> updateUsername(String newUsername) async {
    final token = await getToken();
    final userId = await getUserId();

    if (token == null || token.isEmpty) {
      return {'ok': false, 'message': 'Token жоқ'};
    }
    if (userId == null) {
      return {'ok': false, 'message': 'user_id жоқ'};
    }
    if (newUsername.trim().isEmpty) {
      return {'ok': false, 'message': 'Аты бос болмау керек'};
    }

    final uri = Uri.parse('$baseUrl/user/me/username');

    final res = await http
        .patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': newUsername.trim()}),
    )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic> data = {};
    try {
      if (res.body.isNotEmpty) data = jsonDecode(res.body);
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final updated =
      (data['username'] ?? data['user']?['username'] ?? newUsername.trim())
          .toString();

      await saveUsernameForUser(userId, updated);
      return {'ok': true, 'username': updated};
    }

    return {
      'ok': false,
      'message': data['message'] ?? 'Update username error ${res.statusCode}',
    };
  }

  // ================= LOGOUT =================

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('user_id'); // ✅ current user id кетсін
    await prefs.remove('nickname'); // ✅ ескі жалпы key болса кетсін
    // username_u_<id> әдейі өшірмейміз (келесі login-да басқа userId болады)
    // ❗ Scenario флагтарын өшірмейміз
  }
}