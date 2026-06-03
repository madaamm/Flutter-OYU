import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kazakh_learning_app/models/task_model.dart';

class AdminTaskService {
  static const String baseUrl = 'https://learnkz.kazi.rocks';

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _token();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _multipartHeaders() async {
    final token = await _token();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  List<TaskModel> _parseTasks(dynamic decoded) {
    if (decoded is List) {
      return decoded.map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    if (decoded is Map<String, dynamic>) {
      final raw = decoded['tasks'] ?? decoded['data'] ?? decoded['items'] ?? decoded['rows'] ?? decoded['result'];

      if (raw is List) {
        return raw.map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    }

    return [];
  }

  Future<List<TaskModel>> getLessonTasks(int lessonId) async {
    final url = '$baseUrl/api/lessons/$lessonId/tasks';

    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Тапсырмаларды алу ?атесі: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final tasks = _parseTasks(decoded);

    final visible = tasks.where((e) => e.isArchived == false).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return visible;
  }

  Future<String> uploadTaskAudio({
    required PlatformFile file,
    String? title,
  }) async {
    if (file.bytes == null) {
      throw Exception('Audio file bytes not found. Pick the file again.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/admin/tasks/audio-upload'),
    );

    request.headers.addAll(await _multipartHeaders());
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ),
    );

    if (title != null && title.trim().isNotEmpty) {
      request.fields['title'] = title.trim();
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Аудио ж?ктеу ?атесі: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final audioUrl = decoded['audioUrl']?.toString().trim() ?? '';

    if (audioUrl.isEmpty) {
      throw Exception('Audio upload succeeded but audioUrl was empty');
    }

    return audioUrl;
  }

  List<Map<String, dynamic>> _pairsToJson(List<dynamic>? matchingPairs) {
    if (matchingPairs == null) {
      return <Map<String, dynamic>>[];
    }

    return matchingPairs.asMap().entries.map((entry) {
      final pair = entry.value;

      return {
        'id': pair.id ?? (entry.key + 1),
        'left': pair.left,
        'right': pair.right,
      };
    }).toList();
  }

  Map<String, dynamic> _buildTaskPayload({
    required String type,
    required String promptLang,
    required String targetLang,
    String? promptText,
    List<String>? optionsWords,
    List<String>? correctWords,
    String? audioUrl,
    String? audioText,
    String? translateText,
    List<dynamic>? matchingPairs,
    required int xpReward,
    required int orderIndex,
  }) {
    final Map<String, dynamic> body = {
      'type': type,
      'promptLang': promptLang,
      'targetLang': targetLang,
      'xpReward': xpReward,
      'orderIndex': orderIndex,
    };

    switch (type) {
      case 'SENTENCE_BUILD':
        body['promptText'] = promptText;
        body['optionsWords'] = optionsWords ?? <String>[];
        body['correctWords'] = correctWords ?? <String>[];
        break;

      case 'AUDIO_DICTATION':
        body['audioUrl'] = audioUrl;
        body['audioText'] = audioText;
        break;

      case 'AUDIO_TRANSLATE':
        body['audioUrl'] = audioUrl;
        body['translateText'] = translateText;
        break;

      case 'WORD_MATCH':
        body['matchingPairs'] = _pairsToJson(matchingPairs);
        break;
    }

    body.removeWhere((key, value) => value == null);

    return body;
  }

  Future<TaskModel> createTask({
    required int lessonId,
    required String type,
    required String promptLang,
    required String targetLang,
    String? promptText,
    List<String>? optionsWords,
    List<String>? correctWords,
    String? audioUrl,
    String? audioText,
    String? translateText,
    List<dynamic>? matchingPairs,
    required int xpReward,
    required int orderIndex,
  }) async {
    final body = _buildTaskPayload(
      type: type,
      promptLang: promptLang,
      targetLang: targetLang,
      promptText: promptText,
      optionsWords: optionsWords,
      correctWords: correctWords,
      audioUrl: audioUrl,
      audioText: audioText,
      translateText: translateText,
      matchingPairs: matchingPairs,
      xpReward: xpReward,
      orderIndex: orderIndex,
    );

    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/lessons/$lessonId/tasks'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Тапсырма ?осу ?атесі: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded['task'] ?? decoded['data'] ?? decoded;

    return TaskModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TaskModel> updateTask({
    required int taskId,
    required String type,
    required String promptLang,
    required String targetLang,
    String? promptText,
    List<String>? optionsWords,
    List<String>? correctWords,
    String? audioUrl,
    String? audioText,
    String? translateText,
    List<dynamic>? matchingPairs,
    required int xpReward,
    required int orderIndex,
  }) async {
    final body = _buildTaskPayload(
      type: type,
      promptLang: promptLang,
      targetLang: targetLang,
      promptText: promptText,
      optionsWords: optionsWords,
      correctWords: correctWords,
      audioUrl: audioUrl,
      audioText: audioText,
      translateText: translateText,
      matchingPairs: matchingPairs,
      xpReward: xpReward,
      orderIndex: orderIndex,
    );

    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/tasks/$taskId'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Тапсырма ?згерту ?атесі: ${response.body}');
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
      throw Exception('Архивтеу ?атесі: ${response.body}');
    }
  }
}

