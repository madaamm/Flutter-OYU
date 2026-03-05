import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/auth_service.dart';

class ChatService {
  static Future<String> sendMessage({
    required int userId,
    required String message,
  }) async {
    final token = await AuthService().getToken(); // backend auth сұраса
    final uri = Uri.parse('${AuthService.baseUrl}/chat/chat');

    final res = await http
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "userId": userId,
        "message": message,
      }),
    )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Chat error ${res.statusCode}: ${res.body}');
    }

    // ✅ кейде backend JSON, кейде plain string, кейде JSON string қайтарады
    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      return res.body.toString().trim();
    }

    // ✅ 1) Егер Map болса — aiMessage бірінші
    if (decoded is Map<String, dynamic>) {
      final ai = decoded['aiMessage'] ??
          decoded['reply'] ??
          decoded['answer'] ??
          decoded['message'] ??
          decoded['text'] ??
          decoded['data'];

      return (ai ?? '').toString().trim();
    }

    // ✅ 2) Егер String болса — ішінде JSON string болуы мүмкін
    if (decoded is String) {
      final s = decoded.trim();

      // ішіндегі JSON-ды тағы parse жасап көреміз
      try {
        final inner = jsonDecode(s);
        if (inner is Map<String, dynamic>) {
          final ai = inner['aiMessage'] ??
              inner['reply'] ??
              inner['answer'] ??
              inner['message'] ??
              inner['text'] ??
              inner['data'];
          return (ai ?? '').toString().trim();
        }
      } catch (_) {}

      return s;
    }

    return res.body.toString().trim();
  }
}