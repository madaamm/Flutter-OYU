class BookModel {
  final int id;
  final String title;
  final String author;
  final String format;
  final int pageCount;
  final String genre;
  final String description;
  final String level;
  final String fileUrl;
  final String externalUrl;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.format,
    required this.pageCount,
    required this.genre,
    required this.description,
    required this.level,
    required this.fileUrl,
    required this.externalUrl,
  });

  bool get hasExternalUrl => externalUrl.trim().isNotEmpty;

  factory BookModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      return int.tryParse('$value') ?? fallback;
    }

    return BookModel(
      id: toInt(json['id']),
      title: (json['title'] ?? 'Untitled').toString().trim(),
      author: (json['author'] ?? 'Unknown').toString().trim(),
      format: (json['format'] ?? '').toString().trim().toLowerCase(),
      pageCount: toInt(json['pageCount']),
      genre: ((json['genre'] ?? 'General').toString().trim()).isEmpty
          ? 'General'
          : (json['genre'] ?? 'General').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      level: (json['level'] ?? 'A0').toString().trim().toUpperCase(),
      fileUrl: (json['fileUrl'] ?? '').toString().trim(),
      externalUrl: (json['externalUrl'] ?? '').toString().trim(),
    );
  }
}
