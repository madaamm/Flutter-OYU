import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/models/lesson_model.dart';
import 'package:kazakh_learning_app/models/task_model.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonService {
  static const String baseUrl = 'https://learnkz.kazi.rocks/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _extractData(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded['tasks'] ??
          decoded['lessons'] ??
          decoded['data'] ??
          decoded['items'] ??
          decoded['rows'] ??
          decoded['result'] ??
          decoded;
    }
    return decoded;
  }

  Exception _buildException(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return Exception(
          decoded['message']?.toString() ??
              decoded['error']?.toString() ??
              decoded['details']?.toString() ??
              'Request failed: ${response.statusCode}',
        );
      }
    } catch (_) {}

    return Exception(
      'Request failed: ${response.statusCode}. Body: ${response.body}',
    );
  }

  bool _isTaskUsable(TaskModel task) {
    final hasPrompt = task.promptText.trim().isNotEmpty;

    final hasOptions = task.optionsWords
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .isNotEmpty;

    final hasCorrect = task.correctWords
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .isNotEmpty;

    return hasPrompt && hasOptions && hasCorrect && task.isArchived == false;
  }

  Future<List<LessonModel>> getUserLessons() async {
    final response = await http.get(
      Uri.parse('$baseUrl/lessons'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    final decoded = jsonDecode(response.body);
    final raw = _extractData(decoded);

    if (raw is! List) return <LessonModel>[];

    final lessons = raw
        .whereType<Map<String, dynamic>>()
        .map(LessonModel.fromJson)
        .where((lesson) => lesson.isArchived == false)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return lessons;
  }

  Future<List<TaskModel>> getLessonTasks(int lessonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/lessons/$lessonId/tasks'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    final decoded = jsonDecode(response.body);
    final raw = _extractData(decoded);

    if (raw is! List) return <TaskModel>[];

    final tasks = raw
        .whereType<Map<String, dynamic>>()
        .map(TaskModel.fromJson)
        .where(_isTaskUsable)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return tasks;
  }

  // 10) Отправить ответ на задание
  Future<void> submitTaskAnswer({
    required int taskId,
    required List<String> answerWords,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token жоқ. Қайта login жасаңыз.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'answerWords': answerWords,
      }),
    );

    print('Submit status: ${response.statusCode}');
    print('Submit body: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Submit error ${response.statusCode}: ${response.body}');
    }
  }

  // 11) Получить прогресс конкретного урока
  Future<Map<String, dynamic>> getLessonProgress(int lessonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/progress/lessons/$lessonId'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  // 12) Получить весь прогресс пользователя
  Future<dynamic> getMyProgress() async {
    final response = await http.get(
      Uri.parse('$baseUrl/progress/me'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    return _extractData(jsonDecode(response.body));
  }

  // 13) Получить пройденные уровни
  Future<dynamic> getCompletedLevels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/progress/levels'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    return _extractData(jsonDecode(response.body));
  }

  // 14) Получить серию дней streak
  Future<Map<String, dynamic>> getMyStreak() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/streak'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  // 15) Лидерборд
  Future<dynamic> getLeaderboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/leaderboard'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    return _extractData(jsonDecode(response.body));
  }
}