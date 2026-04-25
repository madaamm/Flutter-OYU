import 'dart:convert';

class TaskModel {
  final int id;
  final int? lessonId;
  final String promptLang;
  final String targetLang;
  final String promptText;
  final List<String> optionsWords;
  final List<String> correctWords;
  final int xpReward;
  final int orderIndex;
  final bool isArchived;

  const TaskModel({
    required this.id,
    this.lessonId,
    required this.promptLang,
    required this.targetLang,
    required this.promptText,
    required this.optionsWords,
    required this.correctWords,
    required this.xpReward,
    required this.orderIndex,
    required this.isArchived,
  });

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? fallback;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final raw = value?.toString().trim().toLowerCase() ?? '';
    return raw == 'true' || raw == '1';
  }

  static String _cleanWord(String value) {
    var result = value.trim();

    while (result.startsWith('"') || result.startsWith("'")) {
      result = result.substring(1).trim();
    }

    while (result.endsWith('"') || result.endsWith("'")) {
      result = result.substring(0, result.length - 1).trim();
    }

    return result.trim();
  }

  static List<String> _splitWords(String raw) {
    return raw
        .replaceAll(',', ' ')
        .split(RegExp(r'\s+'))
        .map(_cleanWord)
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return <String>[];

    if (value is List) {
      return value
          .expand((e) => _splitWords(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
    }

    String raw = value.toString().trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return <String>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
            .expand((e) => _splitWords(e.toString()))
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    if (raw.startsWith('{') && raw.endsWith('}')) {
      raw = raw.substring(1, raw.length - 1);
    }

    return _splitWords(raw);
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawOptions =
        json['optionsWords'] ?? json['options_words'] ?? json['words'];

    final rawCorrect =
        json['correctWords'] ?? json['correct_words'] ?? json['answer_words'];

    return TaskModel(
      id: _toInt(json['id']),
      lessonId: json['lessonId'] != null
          ? _toInt(json['lessonId'])
          : (json['lesson_id'] != null ? _toInt(json['lesson_id']) : null),
      promptLang: (json['promptLang'] ?? json['prompt_lang'] ?? '')
          .toString()
          .trim(),
      targetLang: (json['targetLang'] ?? json['target_lang'] ?? '')
          .toString()
          .trim(),
      promptText: (json['promptText'] ??
          json['prompt_text'] ??
          json['question'] ??
          json['text'] ??
          '')
          .toString()
          .trim(),
      optionsWords: _parseStringList(rawOptions),
      correctWords: _parseStringList(rawCorrect),
      xpReward: _toInt(json['xpReward'] ?? json['xp_reward'], fallback: 10),
      orderIndex: _toInt(json['orderIndex'] ?? json['order_index']),
      isArchived: _toBool(json['isArchived'] ?? json['is_archived']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'promptLang': promptLang,
      'targetLang': targetLang,
      'promptText': promptText,
      'optionsWords': optionsWords,
      'correctWords': correctWords,
      'xpReward': xpReward,
      'orderIndex': orderIndex,
      'isArchived': isArchived,
    };
  }

  TaskModel copyWith({
    int? id,
    int? lessonId,
    String? promptLang,
    String? targetLang,
    String? promptText,
    List<String>? optionsWords,
    List<String>? correctWords,
    int? xpReward,
    int? orderIndex,
    bool? isArchived,
  }) {
    return TaskModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      promptLang: promptLang ?? this.promptLang,
      targetLang: targetLang ?? this.targetLang,
      promptText: promptText ?? this.promptText,
      optionsWords: optionsWords ?? this.optionsWords,
      correctWords: correctWords ?? this.correctWords,
      xpReward: xpReward ?? this.xpReward,
      orderIndex: orderIndex ?? this.orderIndex,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}