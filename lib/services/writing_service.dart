import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/auth_service.dart';

class WritingService {
  static Future<String> evaluateWriting({
    required int userId,
    required String topic,
    required String text,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final token = await AuthService().getToken();
    final uri = Uri.parse('${AuthService.baseUrl}/writing/evaluate');

    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'userId': userId,
            'topic': topic,
            'text': text,
          }),
        )
        .timeout(timeout);

    if (res.statusCode != 200 && res.statusCode != 201) {
      String details = res.body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final messageText = (decoded['message'] ?? 'Writing error').toString().trim();
          final detailsText = (decoded['details'] ?? '').toString().trim();
          details = detailsText.isNotEmpty ? '$messageText: $detailsText' : messageText;
        }
      } catch (_) {}
      throw Exception('Writing error ${res.statusCode}: $details');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      return res.body.toString().trim();
    }

    if (decoded is Map<String, dynamic>) {
      final feedback = decoded['feedback'] ?? decoded['reply'] ?? decoded['answer'] ?? decoded['message'];
      return (feedback ?? '').toString().trim();
    }

    if (decoded is String) {
      return decoded.trim();
    }

    return res.body.toString().trim();
  }
}
