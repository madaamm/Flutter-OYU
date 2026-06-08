import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/models/lesson_model.dart';
import 'package:kazakh_learning_app/models/task_model.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonService {
  static const String baseUrl = 'https://learnkz.kazi.rocks/api';
  static const Map<String, int> _levelOrder = {
    'A0': 0,
    'A1': 1,
    'A2': 2,
    'B1': 3,
    'B2': 4,
    'C1': 5,
    'C2': 6,
  };

  int _levelRank(String level) {
    return _levelOrder[level.trim().toUpperCase()] ?? 0;
  }


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
        return _hasString(task.audioUrl);

      case 'AUDIO_TRANSLATE':
        return _hasString(task.audioUrl);

      default:
        return false;
    }
  }

  Future<List<LessonModel>> getUserLessons() async {
    final headers = await _headers();
    final responses = await Future.wait([
      http.get(Uri.parse('$baseUrl/lessons'), headers: headers),
      http.get(Uri.parse('$baseUrl/progress/me'), headers: headers),
    ]);

    final lessonsResponse = responses[0];
    final progressResponse = responses[1];

    if (lessonsResponse.statusCode < 200 || lessonsResponse.statusCode >= 300) {
      throw _buildException(lessonsResponse);
    }

    final lessonsDecoded = jsonDecode(lessonsResponse.body);
    final lessonsRaw = _extractData(lessonsDecoded);

    if (lessonsRaw is! List) return <LessonModel>[];

    final progressByLessonId = <int, String>{};
    if (progressResponse.statusCode >= 200 && progressResponse.statusCode < 300) {
      final progressDecoded = jsonDecode(progressResponse.body);
      final progressRaw = _extractData(progressDecoded);

      if (progressRaw is List) {
        for (final row in progressRaw.whereType<Map<String, dynamic>>()) {
          final lessonId = int.tryParse('${row['lessonId'] ?? row['id'] ?? row['lesson_id']}');
          if (lessonId != null) {
            progressByLessonId[lessonId] =
                (row['status'] ?? 'NOT_STARTED').toString().trim().toUpperCase();
          }
        }
      }
    }

    final lessons = lessonsRaw
        .whereType<Map<String, dynamic>>()
        .map(LessonModel.fromJson)
        .where((lesson) => lesson.isArchived == false)
        .map(
          (lesson) => lesson.copyWith(
            progressStatus: progressByLessonId[lesson.id] ?? 'NOT_STARTED',
          ),
        )
        .toList()
      ..sort((a, b) {
        final levelCompare = _levelRank(a.level).compareTo(_levelRank(b.level));
        if (levelCompare != 0) return levelCompare;

        final orderCompare = a.orderIndex.compareTo(b.orderIndex);
        if (orderCompare != 0) return orderCompare;

        return a.id.compareTo(b.id);
      });

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

  Future<Map<String, dynamic>> submitTaskAnswer({
    required int taskId,
    List<String>? answerWords,
    String? answerText,
    List<Map<String, String>>? answerPairs,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token missing. Please log in again.');
    }

    final body = <String, dynamic>{};

    if (answerWords != null) {
      body['answerWords'] = answerWords;
    }

    if (answerText != null && answerText.trim().isNotEmpty) {
      body['answerText'] = answerText.trim();
    }

    if (answerPairs != null) {
      body['answerPairs'] = answerPairs;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('Submit status: ${response.statusCode}');
    print('Submit body: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Submit error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
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

  Future<List<Map<String, dynamic>>> getCircleRewardClaims() async {
    final response = await http.get(
      Uri.parse('$baseUrl/progress/circle-rewards'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildException(response);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <Map<String, dynamic>>[];

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> claimCircleReward({
    required String level,
    required int groupIndex,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token missing. Please log in again.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/progress/circle-rewards/claim'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'level': level,
        'groupIndex': groupIndex,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Circle reward error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
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




