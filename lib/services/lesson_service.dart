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

  bool _hasString(String value) {
    return value.trim().isNotEmpty;
  }

  bool _hasWords(List<String> words) {
    return words.map((e) => e.trim()).where((e) => e.isNotEmpty).isNotEmpty;
  }

  bool _isTaskUsable(TaskModel task) {
    if (task.isArchived) return false;

    switch (task.type) {
      case 'SENTENCE_BUILD':
        return _hasString(task.promptText) &&
            _hasWords(task.optionsWords) &&
            _hasWords(task.correctWords);

      case 'WORD_MATCH':
        return task.matchingPairs.isNotEmpty;

      case 'AUDIO_DICTATION':
        return _hasString(task.audioUrl) && _hasString(task.audioText);

      case 'AUDIO_TRANSLATE':
        return _hasString(task.audioUrl) && _hasString(task.translateText);

      default:
        return false;
    }
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
