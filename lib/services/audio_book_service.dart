import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/models/audio_book_model.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';

class AudioBookService {
  Future<List<AudioBookModel>> getAudioBooks() async {
    final response = await http
        .get(Uri.parse('${AuthService.baseUrl}/audio-books'))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load audio books: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid audio books response');
    }

    return decoded
        .whereType<Map>()
        .map((item) => AudioBookModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
