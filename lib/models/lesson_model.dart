class LessonModel {
  final int id;
  final String title;
  final String description;
  final String lectureText;
  final String level;
  final int orderIndex;
  final bool isArchived;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lectureText,
    required this.level,
    required this.orderIndex,
    required this.isArchived,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('${value ?? 0}') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1';
    }
    return false;
  }

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      lectureText: (json['lectureText'] ??
          json['lecture_text'] ??
          json['theory'] ??
          json['content'] ??
          json['body'] ??
          '')
          .toString(),
      level: (json['level'] ?? '').toString(),
      orderIndex: _toInt(json['orderIndex'] ?? json['order_index']),
      isArchived: _toBool(json['isArchived'] ?? json['is_archived']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lectureText': lectureText,
      'level': level,
      'orderIndex': orderIndex,
      'isArchived': isArchived,
    };
  }

  LessonModel copyWith({
    int? id,
    String? title,
    String? description,
    String? lectureText,
    String? level,
    int? orderIndex,
    bool? isArchived,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lectureText: lectureText ?? this.lectureText,
      level: level ?? this.level,
      orderIndex: orderIndex ?? this.orderIndex,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}