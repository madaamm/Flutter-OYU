import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kazakh_learning_app/models/lesson_model.dart';
import 'package:kazakh_learning_app/services/api_config.dart';

class AdminLessonService {
  static const String baseUrl = 'https://oyu-learnkz.onrender.com';

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _token();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  List<LessonModel> _parseLessons(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .map((e) => LessonModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final raw = decoded['lessons'] ??
          decoded['data'] ??
          decoded['items'] ??
          decoded['rows'] ??
          decoded['result'];

      if (raw is List) {
        return raw
            .map((e) => LessonModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return [];
  }

  Future<List<LessonModel>> getAdminLessons() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/lessons'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Уроктарды алу қатесі: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final lessons = _parseLessons(decoded);

    lessons.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return lessons;
  }

  Future<LessonModel> createLesson({
    required String title,
    required String description,
    required String lectureText,
    required String level,
    required int orderIndex,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/lessons'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'lectureText': lectureText,
        'level': level,
        'orderIndex': orderIndex,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Урок қосу қатесі: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded['lesson'] ?? decoded['data'] ?? decoded;

    return LessonModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<LessonModel> updateLesson({
    required int lessonId,
    required String title,
    required String description,
    required String lectureText,
    required String level,
    required int orderIndex,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/lessons/$lessonId'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'lectureText': lectureText,
        'level': level,
        'orderIndex': orderIndex,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Урок өзгерту қатесі: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded['lesson'] ?? decoded['data'] ?? decoded;

    return LessonModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> archiveLesson({
    required int lessonId,
    required bool isArchived,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/lessons/$lessonId/archive'),
      headers: await _headers(),
      body: jsonEncode({
        'isArchived': isArchived,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Архивтеу қатесі: ${response.body}');
    }
  }
}