import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/models/book_review_model.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';

enum ReviewContentType { book, audioBook }

class BookReviewService {
  final AuthService _authService = AuthService();

  String _path(ReviewContentType type, int contentId) {
    final segment = type == ReviewContentType.book ? 'books' : 'audio-books';
    return '/reviews/$segment/$contentId';
  }

  Future<BookReviewSummary> getReviews({
    required ReviewContentType type,
    required int contentId,
  }) async {
    final response = await http
        .get(Uri.parse('${AuthService.baseUrl}${_path(type, contentId)}'))
        .timeout(const Duration(seconds: 20));

    final data = _parseMap(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        (data['message'] ?? 'Failed to load reviews').toString(),
      );
    }

    return BookReviewSummary.fromJson(data);
  }

  Future<void> saveReview({
    required ReviewContentType type,
    required int contentId,
    required int rating,
    required String comment,
  }) async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please sign in to leave a review');
    }

    final response = await http
        .put(
          Uri.parse('${AuthService.baseUrl}${_path(type, contentId)}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'rating': rating,
            'comment': comment.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _parseMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        (data['message'] ?? 'Failed to save review').toString(),
      );
    }
  }

  Map<String, dynamic> _parseMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }
}
