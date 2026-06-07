class DictionaryEntryModel {
  final int id;
  final String word;
  final String translationRu;
  final String translationEn;
  final String transcription;
  final String description;
  final DateTime? createdAt;

  const DictionaryEntryModel({
    required this.id,
    required this.word,
    required this.translationRu,
    required this.translationEn,
    required this.transcription,
    required this.description,
    required this.createdAt,
  });

  String get primaryTranslation {
    if (translationRu.trim().isNotEmpty) return translationRu.trim();
    if (translationEn.trim().isNotEmpty) return translationEn.trim();
    return 'No translation yet';
  }

  factory DictionaryEntryModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    String clean(dynamic value) {
      if (value == null) return '';
      final raw = value.toString().trim();
      return raw.toLowerCase() == 'null' ? '' : raw;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse('$value') ?? 0;
    }

    return DictionaryEntryModel(
      id: parseInt(json['id']),
      word: clean(json['word']),
      translationRu: clean(json['translationRu'] ?? json['translation_ru']),
      translationEn: clean(json['translationEn'] ?? json['translation_en']),
      transcription: clean(json['transcription']),
      description: clean(json['description']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }
}
