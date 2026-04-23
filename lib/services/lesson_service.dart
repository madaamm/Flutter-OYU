import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/models/lesson_model.dart';
import 'package:kazakh_learning_app/models/task_model.dart';
import 'package:kazakh_learning_app/services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonService {
  String get _baseUrl => ApiConfig.baseUrl;

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
      if (decoded['data'] != null) return decoded['data'];
      if (decoded['lessons'] != null) return decoded['lessons'];
      if (decoded['tasks'] != null) return decoded['tasks'];
      if (decoded['items'] != null) return decoded['items'];
    }
    return decoded;
  }

  Exception _buildException(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            decoded['details']?.toString() ??
            'Request failed: ${response.statusCode}';
        return Exception(message);
      }
    } catch (_) {}

    return Exception(
      'Request failed: ${response.statusCode}. Body: ${response.body}',
    );
  }

  bool _isTaskUsable(TaskModel task) {
    final hasCorrect = task.correctWords
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .isNotEmpty;

    final hasOptions = task.optionsWords
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .isNotEmpty;

    final hasPrompt = task.promptText.trim().isNotEmpty;

    return hasCorrect && hasOptions && hasPrompt && !task.isArchived;
  }

  Future<List<LessonModel>> getUserLessons() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/lessons'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    final decoded = jsonDecode(response.body);
    final raw = _extractData(decoded);

    if (raw is! List) {
      return <LessonModel>[];
    }

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
      Uri.parse('$_baseUrl/api/lessons/$lessonId/tasks'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    final decoded = jsonDecode(response.body);
    final raw = _extractData(decoded);

    if (raw is! List) {
      return <TaskModel>[];
    }

    final rawMaps = raw.whereType<Map<String, dynamic>>().toList();

    final parsedTasks = rawMaps.map(TaskModel.fromJson).toList();

    for (int i = 0; i < parsedTasks.length; i++) {
      final task = parsedTasks[i];
      if (!_isTaskUsable(task)) {
        print('INVALID TASK DETECTED');
        print('task.id = ${task.id}');
        print('task.promptText = ${task.promptText}');
        print('task.optionsWords = ${task.optionsWords}');
        print('task.correctWords = ${task.correctWords}');
        print('raw task json = ${rawMaps[i]}');
        print('---------------------------');
      }
    }

    final tasks = parsedTasks
        .where(_isTaskUsable)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return tasks;
  }
}