class BookReviewUser {
  final int id;
  final String username;
  final String nickname;

  const BookReviewUser({
    required this.id,
    required this.username,
    required this.nickname,
  });

  String get displayName {
    if (nickname.isNotEmpty) return nickname;
    if (username.isNotEmpty) return username;
    return 'User $id';
  }

  factory BookReviewUser.fromJson(Map<String, dynamic> json) {
    return BookReviewUser(
      id: _toInt(json['id']),
      username: (json['username'] ?? '').toString().trim(),
      nickname: (json['nickname'] ?? '').toString().trim(),
    );
  }
}

class BookReviewModel {
  final int id;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final BookReviewUser user;

  const BookReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory BookReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime? toDate(dynamic value) {
      final raw = value?.toString().trim() ?? '';
      return raw.isEmpty ? null : DateTime.tryParse(raw);
    }

    final userJson = json['user'];

    return BookReviewModel(
      id: _toInt(json['id']),
      rating: _toInt(json['rating']),
      comment: (json['comment'] ?? '').toString().trim(),
      createdAt: toDate(json['createdAt']),
      updatedAt: toDate(json['updatedAt']),
      user: BookReviewUser.fromJson(
        userJson is Map
            ? Map<String, dynamic>.from(userJson)
            : <String, dynamic>{},
      ),
    );
  }
}

class BookReviewSummary {
  final double averageRating;
  final int reviewCount;
  final List<BookReviewModel> reviews;

  const BookReviewSummary({
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
  });

  factory BookReviewSummary.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviews'];

    return BookReviewSummary(
      averageRating: _toDouble(json['averageRating']),
      reviewCount: _toInt(json['reviewCount']),
      reviews: rawReviews is List
          ? rawReviews
              .whereType<Map>()
              .map(
                (item) => BookReviewModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const <BookReviewModel>[],
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
