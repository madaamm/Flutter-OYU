import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String baseUrl = 'https://learnkz.kazi.rocks/api';

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

  Future<void> resetScenarioForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scenarioKey(email));
  }

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

  Future<void> saveUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  String _nickKey(int userId) => 'nickname_u_$userId';

  Future<void> saveNicknameForUser(int userId, String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nickKey(userId), nickname);
  }

  Future<String?> getNicknameForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nickKey(userId));
  }

  String _usernameKey(int userId) => 'username_u_$userId';

  Future<void> saveUsernameForUser(int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey(userId), username);
  }

  Future<String?> getUsernameForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey(userId));
  }

  Future<String> getCachedUsernameOrDefault() async {
    final userId = await getUserId();
    if (userId == null) return 'User';

    final name = await getUsernameForUser(userId);
    if (name == null || name.trim().isEmpty) return 'User';

    return name.trim();
  }

  Map<String, dynamic> _parseJsonMap(String body) {
    if (body.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  Future<Map<String, String>> _authorizedHeaders({
    bool withJson = false,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token missing (not saved).');
    }

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
    };

    if (withJson) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  Future<Map<String, dynamic>> _authorizedGet(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _authorizedHeaders();

    final res = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    final data = _parseJsonMap(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    throw Exception((data['message'] ?? 'Request failed').toString());
  }

  Future<Map<String, dynamic>> _authorizedPost(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _authorizedHeaders(withJson: true);

    final res = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }

    final data = _parseJsonMap(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    throw Exception((data['message'] ?? 'Request failed').toString());
  }

  Future<void> saveSessionFromResponse(Map<String, dynamic> data) async {
    final token =
        (data['token'] ?? data['accessToken'] ?? '').toString().trim();

    if (token.isEmpty) {
      throw Exception('Token not received');
    }

    await saveToken(token);

    final user = (data['user'] is Map<String, dynamic>)
        ? data['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    final roleRaw = (user['role'] ?? data['role'] ?? 'USER').toString().trim();
    await saveRole(roleRaw.toLowerCase());

    final idRaw = user['id'] ?? data['userId'];
    final userId = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;
    if (userId > 0) {
      await saveUserId(userId);
    }

    final username =
        (user['username'] ?? user['name'] ?? data['username'] ?? '')
            .toString()
            .trim();
    if (userId > 0 && username.isNotEmpty) {
      await saveUsernameForUser(userId, username);
    }

    final nickname =
        (user['nickname'] ?? user['nickName'] ?? user['handle'] ?? '')
            .toString()
            .trim();
    if (userId > 0 && nickname.isNotEmpty) {
      await saveNicknameForUser(userId, nickname);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');

    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'password': password.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _parseJsonMap(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      await saveSessionFromResponse(data);
      return data;
    }

    throw Exception((data['message'] ?? 'Login failed').toString());
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String repeatPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');

    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username.trim(),
            'email': email.trim(),
            'password': password.trim(),
            'repeatPassword': repeatPassword.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _parseJsonMap(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    throw Exception((data['message'] ?? 'Registration failed').toString());
  }

  Future<Map<String, dynamic>> me() async {
    final decoded = await _authorizedGet('/user/me');

    final userId = await getUserId();
    if (userId != null) {
      final username =
          (decoded['username'] ?? decoded['user']?['username'] ?? '')
              .toString()
              .trim();
      if (username.isNotEmpty) {
        await saveUsernameForUser(userId, username);
      }
    }

    return decoded;
  }

  Future<Map<String, dynamic>> getInitialSetupStatus() async {
    return _authorizedGet('/user/onboarding/status');
  }

  Future<Map<String, dynamic>> getInitialSetupLanguages() async {
    return _authorizedGet('/user/onboarding/languages');
  }

  Future<Map<String, dynamic>> saveInterfaceLanguage(String language) async {
    return _authorizedPost(
      '/user/onboarding/language',
      body: {'language': language.trim().toLowerCase()},
    );
  }

  Future<Map<String, dynamic>> getPlacementTestQuestions() async {
    return _authorizedGet('/user/onboarding/placement-test');
  }

  Future<Map<String, dynamic>> startFromZero() async {
    return _authorizedPost('/user/onboarding/start-from-zero');
  }

  Future<Map<String, dynamic>> submitPlacementTest(
    List<Map<String, dynamic>> answers,
  ) async {
    return _authorizedPost(
      '/user/onboarding/placement-test',
      body: {'answers': answers},
    );
  }

  Future<Map<String, dynamic>> updateUsername(String newUsername) async {
    final token = await getToken();
    final userId = await getUserId();

    if (token == null || token.isEmpty) {
      return {'ok': false, 'message': 'No token'};
    }
    if (userId == null) {
      return {'ok': false, 'message': 'user_id missing'};
    }
    if (newUsername.trim().isEmpty) {
      return {'ok': false, 'message': 'The name must not be empty.'};
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

    final data = _parseJsonMap(res.body);

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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('user_id');
    await prefs.remove('nickname');
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email'],
    );

    final GoogleSignInAccount? account = await googleSignIn.signIn();

    if (account == null) {
      throw Exception('Sign-in was cancelled');
    }

    final GoogleSignInAuthentication auth = await account.authentication;

    final String? idToken = auth.idToken;

    if (idToken == null) {
      throw Exception('Google did not return an idToken');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'idToken': idToken,
      }),
    );

    final data = _parseJsonMap(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await saveSessionFromResponse(data);
      return data;
    }

    throw Exception(
      data['message'] ?? 'Google login failed',
    );
  }
}



