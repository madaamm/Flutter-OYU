import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';

class AlphabetService {
  static String get baseUrl => AuthService.baseUrl;

  Future<List<dynamic>> getAll() async {
    final res = await http.get(
      Uri.parse('$baseUrl/alphabet'),
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      throw Exception('Alphabet response is not a list');
    }

    throw Exception('Ошибка загрузки алфавита: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/alphabet/$id'),
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Letter response is not an object');
    }

    throw Exception('Ошибка загрузки буквы: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> adminGetById(int id) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token жоқ. Қайта login жаса.');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/admin/alphabet/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Admin letter response is not an object');
    }

    throw Exception(
      'Ошибка загрузки admin буквы: ${res.statusCode} ${res.body}',
    );
  }

  Future<void> delete(int id) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token жоқ. Қайта login жаса.');
    }

    final res = await http.delete(
      Uri.parse('$baseUrl/admin/alphabet/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Delete error: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token жоқ. Қайта login жаса.');
    }

    final res = await http.post(
      Uri.parse('$baseUrl/admin/alphabet'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Create error: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token жоқ. Қайта login жаса.');
    }

    final res = await http.put(
      Uri.parse('$baseUrl/admin/alphabet/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Update error: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> uploadAudio({
    required int id,
    required String fileName,
    String? filePath,
    List<int>? fileBytes,
  }) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token жоқ. Қайта login жаса.');
    }

    final lower = fileName.toLowerCase();
    const allowedExtensions = ['.mp3', '.wav', '.ogg'];
    final isAllowed = allowedExtensions.any(lower.endsWith);

    if (!isAllowed) {
      throw Exception('Тек mp3, wav, ogg файл жүкте');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/admin/alphabet/$id/audio'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    if (fileBytes != null && fileBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: _guessAudioType(fileName),
        ),
      );
    } else if (filePath != null && filePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
          contentType: _guessAudioType(fileName),
        ),
      );
    } else {
      throw Exception('Файл таңдалмады');
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Audio upload error: ${response.statusCode} ${response.body}',
      );
    }
  }

  String buildAudioApiUrl(int id) {
    final apiBase = baseUrl.trim();
    final origin = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;

    return '$origin/api/alphabet/$id/audio';
  }

  Future<bool> audioExists(int id) async {
    try {
      final res = await http.get(
        Uri.parse(buildAudioApiUrl(id)),
        headers: const {'Accept': '*/*'},
      );

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  MediaType _guessAudioType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.mp3')) return MediaType('audio', 'mpeg');
    if (lower.endsWith('.wav')) return MediaType('audio', 'wav');
    if (lower.endsWith('.ogg')) return MediaType('audio', 'ogg');

    return MediaType('application', 'octet-stream');
  }
}