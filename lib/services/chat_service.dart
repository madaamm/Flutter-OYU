import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/services/chat_session_service.dart';

class ChatService {
  static const int _maxStoredMessageChars = 1700;
  static const int _maxHistoryItems = 4;
  static const int _maxHistoryEntryChars = 180;
  static const String _responseGuard =
      'Reply in the same language as the user. Keep the answer short, helpful, '
      'and under 700 characters. Use simple text without long lists.';

  static Future<String> sendMessage({
    required int userId,
    required String message,
    List<AiChatMessage> history = const [],
    Duration timeout = const Duration(seconds: 250),
  }) async {
    final token = await AuthService().getToken(); // backend auth сұраса
    final uri = Uri.parse('${AuthService.baseUrl}/chat/chat');
    final prompt = _buildPrompt(message: message, history: history);

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
            "message": prompt,
          }),
        )
        .timeout(timeout);

    if (res.statusCode != 200 && res.statusCode != 201) {
      String details = res.body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final messageText =
              (decoded['message'] ?? 'Chat error').toString().trim();
          final detailsText = (decoded['details'] ?? '').toString().trim();
          details = detailsText.isNotEmpty
              ? '$messageText: $detailsText'
              : messageText;
        }
      } catch (_) {}
      throw Exception('Chat error ${res.statusCode}: $details');
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

  static String _buildPrompt({
    required String message,
    required List<AiChatMessage> history,
  }) {
    final recentMessages = history
        .where((m) => m.text.trim().isNotEmpty && m.text.trim() != '...')
        .toList();

    final start = recentMessages.length > _maxHistoryItems
        ? recentMessages.length - _maxHistoryItems
        : 0;
    final visibleHistory = recentMessages.sublist(start);

    final historyBlock = visibleHistory
        .map(
          (m) =>
              '${m.isAi ? 'Assistant' : 'User'}: ${_clip(m.text.trim(), _maxHistoryEntryChars)}',
        )
        .join('\n');

    final prompt = [
      _responseGuard,
      'Use the conversation history below to keep context only for this current session.',
      if (historyBlock.isNotEmpty) 'Conversation history:\n$historyBlock',
      'Latest user message: ${_clip(message.trim(), 400)}',
    ].join('\n\n');

    return _clip(prompt, _maxStoredMessageChars);
  }

  static String _clip(String value, int maxChars) {
    if (value.length <= maxChars) return value;
    return '${value.substring(0, maxChars - 3)}...';
  }
}
