import 'dart:convert';

class MatchingPair {
  final int id;
  final String left;
  final String right;

  const MatchingPair({
    required this.id,
    required this.left,
    required this.right,
  });

  factory MatchingPair.fromJson(Map<String, dynamic> json) {
    return MatchingPair(
      id: TaskModel.toInt(json['id']),
      left: TaskModel.toCleanString(json['left']),
      right: TaskModel.toCleanString(json['right']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'left': left,
      'right': right,
    };
  }

  MatchingPair copyWith({
    int? id,
    String? left,
    String? right,
  }) {
    return MatchingPair(
      id: id ?? this.id,
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }
}

class TaskModel {
  final int id;
  final int? lessonId;

  /// Supported: SENTENCE_BUILD, AUDIO_DICTATION, AUDIO_TRANSLATE, WORD_MATCH
  final String type;

  final String promptLang;
  final String targetLang;

  /// SENTENCE_BUILD
  final String promptText;
  final List<String> optionsWords;
  final List<String> correctWords;

  /// AUDIO_DICTATION / AUDIO_TRANSLATE
  final String audioUrl;

  /// AUDIO_DICTATION
  final String audioText;

  /// AUDIO_TRANSLATE
  final String translateText;

  /// WORD_MATCH
  final List<MatchingPair> matchingPairs;

  final int xpReward;
  final int orderIndex;
  final bool isArchived;

  const TaskModel({
    required this.id,
    this.lessonId,
    required this.type,
    required this.promptLang,
    required this.targetLang,
    required this.promptText,
    required this.optionsWords,
    required this.correctWords,
    required this.audioUrl,
    required this.audioText,
    required this.translateText,
    required this.matchingPairs,
    required this.xpReward,
    required this.orderIndex,
    required this.isArchived,
  });

  static int toInt(dynamic value, {int fallback = 0}) {
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

  static String toCleanString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final raw = value.toString().trim();
    if (raw.toLowerCase() == 'null') return fallback;
    return raw;
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

  static List<MatchingPair> _parseMatchingPairs(dynamic value) {
    if (value == null) return <MatchingPair>[];

    if (value is List) {
      final pairs = <MatchingPair>[];

      for (int i = 0; i < value.length; i++) {
        final item = value[i];

        if (item is Map) {
          final pair = MatchingPair.fromJson(Map<String, dynamic>.from(item));
          if (pair.left.isNotEmpty && pair.right.isNotEmpty) {
            pairs.add(
              MatchingPair(
                id: pair.id > 0 ? pair.id : i + 1,
                left: pair.left,
                right: pair.right,
              ),
            );
          }
        } else {
          final parsed = _parsePairLine(item.toString(), pairs.length + 1);
          if (parsed != null) pairs.add(parsed);
        }
      }

      return pairs;
    }

    final raw = value.toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return <MatchingPair>[];

    try {
      final decoded = jsonDecode(raw);
      return _parseMatchingPairs(decoded);
    } catch (_) {}

    final lines = raw
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    final pairs = <MatchingPair>[];

    for (final line in lines) {
      final parsed = _parsePairLine(line, pairs.length + 1);
      if (parsed != null) pairs.add(parsed);
    }

    return pairs;
  }

  static MatchingPair? _parsePairLine(String line, int id) {
    final separator = line.contains('|')
        ? '|'
        : line.contains('=')
        ? '='
        : line.contains(':')
        ? ':'
        : null;

    if (separator == null) return null;

    final parts = line.split(separator);
    if (parts.length < 2) return null;

    final left = parts.first.trim();
    final right = parts.sublist(1).join(separator).trim();

    if (left.isEmpty || right.isEmpty) return null;

    return MatchingPair(
      id: id,
      left: left,
      right: right,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawOptions =
        json['optionsWords'] ?? json['options_words'] ?? json['words'];

    final rawCorrect =
        json['correctWords'] ?? json['correct_words'] ?? json['answer_words'];

    final rawPairs =
        json['matchingPairs'] ?? json['matching_pairs'] ?? json['pairs'];

    return TaskModel(
      id: toInt(json['id']),
      lessonId: json['lessonId'] != null
          ? toInt(json['lessonId'])
          : (json['lesson_id'] != null ? toInt(json['lesson_id']) : null),
      type: toCleanString(
        json['type'] ?? json['taskType'] ?? json['task_type'],
        fallback: 'SENTENCE_BUILD',
      ),
      promptLang: toCleanString(json['promptLang'] ?? json['prompt_lang']),
      targetLang: toCleanString(json['targetLang'] ?? json['target_lang']),
      promptText: toCleanString(
        json['promptText'] ??
            json['prompt_text'] ??
            json['question'] ??
            json['text'],
      ),
      optionsWords: _parseStringList(rawOptions),
      correctWords: _parseStringList(rawCorrect),
      audioUrl: toCleanString(json['audioUrl'] ?? json['audio_url']),
      audioText: toCleanString(json['audioText'] ?? json['audio_text']),
      translateText: toCleanString(
        json['translateText'] ?? json['translate_text'] ?? json['translation'],
      ),
      matchingPairs: _parseMatchingPairs(rawPairs),
      xpReward: toInt(json['xpReward'] ?? json['xp_reward'], fallback: 10),
      orderIndex: toInt(json['orderIndex'] ?? json['order_index']),
      isArchived: _toBool(json['isArchived'] ?? json['is_archived']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'type': type,
      'promptLang': promptLang,
      'targetLang': targetLang,
      'promptText': promptText,
      'optionsWords': optionsWords,
      'correctWords': correctWords,
      'audioUrl': audioUrl,
      'audioText': audioText,
      'translateText': translateText,
      'matchingPairs': matchingPairs.map((e) => e.toJson()).toList(),
      'xpReward': xpReward,
      'orderIndex': orderIndex,
      'isArchived': isArchived,
    };
  }

  TaskModel copyWith({
    int? id,
    int? lessonId,
    String? type,
    String? promptLang,
    String? targetLang,
    String? promptText,
    List<String>? optionsWords,
    List<String>? correctWords,
    String? audioUrl,
    String? audioText,
    String? translateText,
    List<MatchingPair>? matchingPairs,
    int? xpReward,
    int? orderIndex,
    bool? isArchived,
  }) {
    return TaskModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      type: type ?? this.type,
      promptLang: promptLang ?? this.promptLang,
      targetLang: targetLang ?? this.targetLang,
      promptText: promptText ?? this.promptText,
      optionsWords: optionsWords ?? this.optionsWords,
      correctWords: correctWords ?? this.correctWords,
      audioUrl: audioUrl ?? this.audioUrl,
      audioText: audioText ?? this.audioText,
      translateText: translateText ?? this.translateText,
      matchingPairs: matchingPairs ?? this.matchingPairs,
      xpReward: xpReward ?? this.xpReward,
      orderIndex: orderIndex ?? this.orderIndex,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
