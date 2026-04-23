import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kazakh_learning_app/models/task_model.dart';
import 'package:kazakh_learning_app/services/api_config.dart';

class AdminTaskService {
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

  List<TaskModel> _parseTasks(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final raw = decoded['tasks'] ??
          decoded['data'] ??
          decoded['items'] ??
          decoded['rows'] ??
          decoded['result'];

      if (raw is List) {
        return raw
            .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    return [];
  }

  Future<List<TaskModel>> getLessonTasks(int lessonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/lessons/$lessonId/tasks'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Тапсырмаларды алу қатесі: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final tasks = _parseTasks(decoded);

    final visible = tasks.where((e) => e.isArchived == false).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return visible;
  }

  Future<TaskModel> createTask({
    required int lessonId,
    required String promptLang,
    required String targetLang,
    required String promptText,
    required List<String> optionsWords,
    required List<String> correctWords,
    required int xpReward,
    required int orderIndex,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/lessons/$lessonId/tasks'),
      headers: await _headers(),
      body: jsonEncode({
        'promptLang': promptLang,
        'targetLang': targetLang,
        'promptText': promptText,
        'optionsWords': optionsWords,
        'correctWords': correctWords,
        'xpReward': xpReward,
        'orderIndex': orderIndex,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Тапсырма қосу қатесі: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded['task'] ?? decoded['data'] ?? decoded;
    return TaskModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TaskModel> updateTask({
    required int taskId,
    String? promptLang,
    String? targetLang,
    String? promptText,
    List<String>? optionsWords,
    List<String>? correctWords,
    int? xpReward,
    int? orderIndex,
  }) async {
    final Map<String, dynamic> body = {};

    if (promptLang != null) body['promptLang'] = promptLang;
    if (targetLang != null) body['targetLang'] = targetLang;
    if (promptText != null) body['promptText'] = promptText;
    if (optionsWords != null) body['optionsWords'] = optionsWords;
    if (correctWords != null) body['correctWords'] = correctWords;
    if (xpReward != null) body['xpReward'] = xpReward;
    if (orderIndex != null) body['orderIndex'] = orderIndex;

    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/tasks/$taskId'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Тапсырма өзгерту қатесі: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded['task'] ?? decoded['data'] ?? decoded;
    return TaskModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> archiveTask({
    required int taskId,
    required bool isArchived,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/tasks/$taskId/archive'),
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