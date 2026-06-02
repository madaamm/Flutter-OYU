class AudioBookModel {
  final int id;
  final String title;
  final String author;
  final String format;
  final String genre;
  final String level;
  final String fileUrl;

  const AudioBookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.format,
    required this.genre,
    required this.level,
    required this.fileUrl,
  });

  factory AudioBookModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      return int.tryParse('$value') ?? fallback;
    }

    return AudioBookModel(
      id: toInt(json['id']),
      title: (json['title'] ?? 'Untitled').toString().trim(),
      author: (json['author'] ?? 'Unknown').toString().trim(),
      format: (json['format'] ?? '').toString().trim().toLowerCase(),
      genre: ((json['genre'] ?? 'General').toString().trim()).isEmpty
          ? 'General'
          : (json['genre'] ?? 'General').toString().trim(),
      level: (json['level'] ?? 'A0').toString().trim().toUpperCase(),
      fileUrl: (json['fileUrl'] ?? '').toString().trim(),
    );
  }
}
