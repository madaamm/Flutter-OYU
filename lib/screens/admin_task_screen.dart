import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminTaskScreen extends StatefulWidget {
  const AdminTaskScreen({super.key});

  @override
  State<AdminTaskScreen> createState() => _AdminTaskScreenState();
}

class _AdminTaskScreenState extends State<AdminTaskScreen> {
  static const String kOyuAsset = "assets/images/Oyu.png";
  static const String kOyuSleepAsset = "assets/images/Oyu_uyktauda.png";
  static const String kEggAsset = "assets/images/Pink_egg.png";
  static const String kBoxAsset = "assets/images/Qorap.png";

  static const int kTasksPerCircle = 6;
  static const int kMaxCircles = 20;

  final _lessonApi = _LessonAdminApi();
  late Future<List<_LessonItem>> _futureLessons;

  @override
  void initState() {
    super.initState();
    _futureLessons = _lessonApi.fetchLessons();
  }

  Future<void> _reload() async {
    setState(() {
      _futureLessons = _lessonApi.fetchLessons();
    });
    await _futureLessons;
  }

  Future<void> _openAddDialog() async {
    final createdLesson = await showDialog<_LessonItem?>(
      context: context,
      builder: (_) => const _AddLessonDialog(),
    );

    if (createdLesson != null) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Урок backend-ке сәтті сақталды')),
      );
    }
  }

  Future<void> _archiveLesson(_LessonItem lesson) async {
    try {
      await _lessonApi.archiveLesson(lesson.id, true);
      await _reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Урок архивке жіберілді: ${lesson.title}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
      );
    }
  }

  Future<void> _openEditDialog(_LessonItem lesson) async {
    final updatedLesson = await showDialog<_LessonItem?>(
      context: context,
      builder: (_) => _AddLessonDialog(lesson: lesson),
    );

    if (updatedLesson != null) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Урок жаңартылды')),
      );
    }
  }

  void _openTaskSheet({required _LessonItem lesson, required int globalIndex}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _TaskActionSheet(
          subtitle:
          lesson.title.isEmpty ? "Say where people are from" : lesson.title,
          lessonNumber: globalIndex + 1,
          level: lesson.level.isEmpty ? "A0" : lesson.level,
          onDelete: () async {
            Navigator.pop(context);
            await _archiveLesson(lesson);
          },
          onEdit: () async {
            Navigator.pop(context);
            await _openEditDialog(lesson);
          },
          onOpenTheory: (level) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TheoryLessonScreen(
                  lessonNumber: globalIndex + 1,
                  level: level,
                  title: lesson.title,
                  description: lesson.description,
                  lectureText: lesson.lectureText,
                ),
              ),
            );
          },
          onOpenExercise: (level) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciseWordOrderScreen(
                  lessonNumber: globalIndex + 1,
                  level: level,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A0CA3),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final base = math.min(c.maxWidth, c.maxHeight);
            final pad = base * 0.035;

            return Padding(
              padding: EdgeInsets.all(pad),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 14,
                        top: 12,
                        child: ElevatedButton.icon(
                          onPressed: _openAddDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Добавить"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A0CA3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            minimumSize: const Size(0, 38),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        top: 88,
                        child: FutureBuilder<List<_LessonItem>>(
                          future: _futureLessons,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3A0CA3),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return RefreshIndicator(
                                onRefresh: _reload,
                                child: ListView(
                                  physics:
                                  const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: c.maxHeight * 0.65,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.cloud_off_rounded,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Уроктар жүктелмеді',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF3A0CA3),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                '${snapshot.error}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              ElevatedButton(
                                                onPressed: _reload,
                                                child:
                                                const Text('Қайта көру'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final lessons = snapshot.data ?? [];

                            if (lessons.isEmpty) {
                              return RefreshIndicator(
                                onRefresh: _reload,
                                child: ListView(
                                  physics:
                                  const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(
                                      height: 650,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Image(
                                              image: AssetImage(
                                                kOyuSleepAsset,
                                              ),
                                              width: 120,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              "Әзірге урок жоқ",
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF3A0CA3),
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              "Добавить арқылы жаңа урок қос",
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final totalTasks = lessons.length;
                            final circles = ((totalTasks + kTasksPerCircle - 1) ~/
                                kTasksPerCircle)
                                .clamp(1, kMaxCircles);

                            return RefreshIndicator(
                              onRefresh: _reload,
                              child: ListView.builder(
                                padding: EdgeInsets.only(
                                  top: base * 0.01,
                                  bottom: base * 0.06,
                                ),
                                itemCount: circles,
                                itemBuilder: (context, idx) {
                                  final start = idx * kTasksPerCircle;
                                  final filled = (totalTasks - start)
                                      .clamp(0, kTasksPerCircle);
                                  final showBox = filled == kTasksPerCircle;

                                  return _CircleBlock(
                                    base: base,
                                    filledTasks: filled,
                                    showBox: showBox,
                                    eggAsset: kEggAsset,
                                    oyuAsset: kOyuAsset,
                                    boxAsset: kBoxAsset,
                                    onTapTask: (taskIndexInCircle) {
                                      final globalIndex =
                                          start + taskIndexInCircle;
                                      if (globalIndex >= totalTasks) return;
                                      final lesson = lessons[globalIndex];
                                      _openTaskSheet(
                                        lesson: lesson,
                                        globalIndex: globalIndex,
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CircleBlock extends StatelessWidget {
  final double base;
  final int filledTasks;
  final bool showBox;
  final String eggAsset;
  final String oyuAsset;
  final String boxAsset;
  final void Function(int taskIndex) onTapTask;

  const _CircleBlock({
    required this.base,
    required this.filledTasks,
    required this.showBox,
    required this.eggAsset,
    required this.oyuAsset,
    required this.boxAsset,
    required this.onTapTask,
  });

  @override
  Widget build(BuildContext context) {
    final double size = base * 0.82;
    final double eggSize = base * 0.16;
    final double oyuSize = base * 0.40;

    return SizedBox(
      height: size,
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                oyuAsset,
                width: oyuSize,
                fit: BoxFit.contain,
              ),
              for (int i = 0; i < filledTasks; i++) _buildEggPosition(i, eggSize),
              if (showBox)
                Positioned(
                  bottom: size * 0.05,
                  child: Image.asset(
                    boxAsset,
                    width: eggSize * 0.95,
                    height: eggSize * 0.95,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEggPosition(int index, double size) {
    const positions = [
      Offset(0, -1.95),
      Offset(-1.6, -0.75),
      Offset(1.6, -0.75),
      Offset(-1.6, 0.95),
      Offset(1.6, 0.95),
      Offset(0, 2.0),
    ];

    final pos = positions[index];

    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: Offset(pos.dx * size * 0.95, pos.dy * size * 0.95),
          child: GestureDetector(
            onTap: () => onTapTask(index),
            child: Image.asset(
              eggAsset,
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskActionSheet extends StatelessWidget {
  final String subtitle;
  final int lessonNumber;
  final String level;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final void Function(String level) onOpenTheory;
  final void Function(String level) onOpenExercise;

  const _TaskActionSheet({
    required this.subtitle,
    required this.lessonNumber,
    required this.level,
    required this.onDelete,
    required this.onEdit,
    required this.onOpenTheory,
    required this.onOpenExercise,
  });

  static const Color sheetPurple = Color(0xFF6A00FF);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          14,
          14,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: sheetPurple,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Level: $level',
                  style: const TextStyle(
                    color: Color(0xFFE9D8FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _whiteButton(
                  text: "Theory",
                  textColor: sheetPurple,
                  onTap: () => onOpenTheory(level),
                ),
                const SizedBox(height: 12),
                _whiteButton(
                  text: "Start exercise",
                  textColor: const Color(0xFFFFB200),
                  onTap: () => onOpenExercise(level),
                ),
                const SizedBox(height: 12),
                _whiteButton(
                  text: "Edit",
                  textColor: sheetPurple,
                  onTap: onEdit,
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _whiteButton({
    required String text,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class TheoryLessonScreen extends StatelessWidget {
  final int lessonNumber;
  final String level;
  final String title;
  final String description;
  final String lectureText;

  const TheoryLessonScreen({
    super.key,
    required this.lessonNumber,
    required this.level,
    required this.title,
    required this.description,
    required this.lectureText,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6A00FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        title: Text(title.isEmpty ? "Theory Lesson $lessonNumber" : title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Level: $level",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: purple,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (description.isNotEmpty) ...[
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (lectureText.trim().isNotEmpty)
                    Text(
                      lectureText.trim(),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    const Text(
                      "Теория әлі қосылмаған",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExerciseWordOrderScreen extends StatefulWidget {
  final int lessonNumber;
  final String level;

  const ExerciseWordOrderScreen({
    super.key,
    required this.lessonNumber,
    required this.level,
  });

  @override
  State<ExerciseWordOrderScreen> createState() => _ExerciseWordOrderScreenState();
}

enum _Stage { building, checkedCorrect }

class _ExerciseWordOrderScreenState extends State<ExerciseWordOrderScreen> {
  static const purple = Color(0xFF6A00FF);
  static const green = Color(0xFF2ECC71);

  static const String kOyuHappy = "assets/images/Oyu.png";
  static const String kOyuSleep = "assets/images/Oyu_uyktauda.png";

  final String promptEn = "I drink water";
  final List<String> correct = const ["Men", "su", "ishemin"];
  final List<String> pool = ["oqiymyn", "ishemin", "Men", "su", "nan"];

  late List<String?> slots;

  _Stage stage = _Stage.building;
  int lives = 3;

  @override
  void initState() {
    super.initState();
    slots = List<String?>.filled(3, null);
  }

  bool get _allFilled => slots.every((e) => e != null);

  bool _isPlaced(String w) => slots.contains(w);

  List<String> get _availableWords => pool.where((w) => !_isPlaced(w)).toList();

  void _placeWord(String w) {
    if (stage != _Stage.building) return;
    final i = slots.indexWhere((e) => e == null);
    if (i == -1) return;
    setState(() => slots[i] = w);
  }

  void _removeFromSlot(int index) {
    if (stage != _Stage.building) return;
    setState(() => slots[index] = null);
  }

  void _check() {
    if (!_allFilled) return;

    final ans = slots.cast<String>();
    final ok = _listEquals(ans, correct);

    if (ok) {
      setState(() => stage = _Stage.checkedCorrect);
    } else {
      setState(() => lives = (lives - 1).clamp(0, 3));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Қате 😅 Қайта көр!")),
      );
    }
  }

  void _continue() => Navigator.pop(context);

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = stage == _Stage.checkedCorrect;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: purple,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.yellow, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        "$lives",
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                ),
                child: Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                      children: [
                        _SpeechTop(text: promptEn),
                        const SizedBox(height: 20),
                        _AnswerLine(
                          words: slots,
                          correctWords: correct,
                          showCorrectStyle: isCorrect,
                          onTapSlot: _removeFromSlot,
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          alignment: WrapAlignment.center,
                          children: _availableWords
                              .map((w) => _WordChip(
                            text: w,
                            onTap: () => _placeWord(w),
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: 34),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Image.asset(
                              isCorrect ? kOyuHappy : kOyuSleep,
                              width: 90,
                              height: 90,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SpeechBottom(
                                text: isCorrect
                                    ? "You did great job"
                                    : "Put the words in\ncorrect order",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isCorrect ? _continue : (_allFilled ? _check : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCorrect
                                ? green
                                : (_allFilled ? green : Colors.grey.shade400),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isCorrect ? "Continue" : (_allFilled ? "Check" : "Continue"),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _WordChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: const Color(0xFF6A00FF).withOpacity(0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  final List<String?> words;
  final List<String> correctWords;
  final bool showCorrectStyle;
  final void Function(int index) onTapSlot;

  const _AnswerLine({
    required this.words,
    required this.correctWords,
    required this.showCorrectStyle,
    required this.onTapSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(words.length, (i) {
            final w = words[i];
            final isFilled = w != null;
            final isCorrectChip = showCorrectStyle && isFilled && w == correctWords[i];

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: isFilled ? 2 : 0,
              shadowColor: const Color(0xFF6A00FF).withOpacity(0.25),
              child: InkWell(
                onTap: isFilled ? () => onTapSlot(i) : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 74),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrectChip
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFF6A00FF).withOpacity(0.35),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    w ?? " ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isCorrectChip ? const Color(0xFF2ECC71) : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Container(height: 1.6, color: Colors.black26),
        const SizedBox(height: 18),
        Container(height: 1.6, color: Colors.black26),
        const SizedBox(height: 18),
        Container(height: 1.6, color: Colors.black26),
      ],
    );
  }
}

class _SpeechTop extends StatelessWidget {
  final String text;
  const _SpeechTop({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.08),
            )
          ],
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _SpeechBottom extends StatelessWidget {
  final String text;
  const _SpeechBottom({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.08),
          )
        ],
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _AddLessonDialog extends StatefulWidget {
  final _LessonItem? lesson;

  const _AddLessonDialog({this.lesson});

  @override
  State<_AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<_AddLessonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _api = _LessonAdminApi();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _lectureTextController;
  late final TextEditingController _orderController;

  String _level = 'A0';
  bool _saving = false;

  bool get _isEdit => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.lesson?.description ?? '');
    _lectureTextController =
        TextEditingController(text: widget.lesson?.lectureText ?? '');
    _orderController = TextEditingController(
      text: (widget.lesson?.orderIndex ?? 0).toString(),
    );
    _level = widget.lesson?.level ?? 'A0';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _lectureTextController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final orderIndex = int.parse(_orderController.text.trim());

      if (_isEdit) {
        final updatedLesson = await _api.updateLesson(
          id: widget.lesson!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          lectureText: _lectureTextController.text.trim(),
          level: _level,
          orderIndex: orderIndex,
        );

        if (!mounted) return;
        Navigator.pop(context, updatedLesson);
      } else {
        final createdLesson = await _api.createLesson(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          lectureText: _lectureTextController.text.trim(),
          level: _level,
          orderIndex: orderIndex,
        );

        if (!mounted) return;
        Navigator.pop(context, createdLesson);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қосу қатесі: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEdit ? 'Урокты өзгерту' : 'Жаңа урок қосу',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3A0CA3),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: _decoration('Title'),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title енгіз' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _decoration('Description'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Description енгіз'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lectureTextController,
                  maxLines: 8,
                  decoration: _decoration('Theory / Lecture text'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Theory text енгіз'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _level,
                  decoration: _decoration('Level'),
                  items: const [
                    DropdownMenuItem(value: 'A0', child: Text('A0')),
                    DropdownMenuItem(value: 'A1', child: Text('A1')),
                    DropdownMenuItem(value: 'A2', child: Text('A2')),
                    DropdownMenuItem(value: 'B1', child: Text('B1')),
                    DropdownMenuItem(value: 'B2', child: Text('B2')),
                    DropdownMenuItem(value: 'C1', child: Text('C1')),
                    DropdownMenuItem(value: 'C2', child: Text('C2')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _level = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Order index'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Order енгіз';
                    if (int.tryParse(v.trim()) == null) return 'Сан енгіз';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A0CA3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                        : Text(_isEdit ? 'Сақтау' : 'Қосу'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF6F1FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _LessonItem {
  final int id;
  final String title;
  final String description;
  final String lectureText;
  final String level;
  final int orderIndex;
  final bool isArchived;

  const _LessonItem({
    required this.id,
    required this.title,
    required this.description,
    required this.lectureText,
    required this.level,
    required this.orderIndex,
    required this.isArchived,
  });

  factory _LessonItem.fromJson(Map<String, dynamic> json) {
    return _LessonItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      lectureText: json['lectureText']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      orderIndex: json['orderIndex'] is int
          ? json['orderIndex']
          : int.tryParse('${json['orderIndex']}') ?? 0,
      isArchived: json['isArchived'] == true,
    );
  }
}

class _LessonAdminApi {
  static const String _baseUrl = 'https://oyu-learnkz.onrender.com';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  List<_LessonItem> _parseLessons(dynamic decoded) {
    final List<_LessonItem> lessons = [];

    if (decoded is List) {
      for (final item in decoded) {
        lessons.add(_LessonItem.fromJson(Map<String, dynamic>.from(item)));
      }
      return lessons;
    }

    if (decoded is Map<String, dynamic>) {
      final raw = decoded['lessons'] ??
          decoded['data'] ??
          decoded['items'] ??
          decoded['rows'] ??
          decoded['result'];

      if (raw is List) {
        for (final item in raw) {
          lessons.add(_LessonItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return lessons;
  }

  Future<List<_LessonItem>> fetchLessons() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/admin/lessons'),
      headers: await _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }

    final decoded = jsonDecode(response.body);
    final lessons = _parseLessons(decoded);

    lessons.removeWhere((e) => e.isArchived);
    lessons.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return lessons;
  }

  Future<_LessonItem> createLesson({
    required String title,
    required String description,
    required String lectureText,
    required String level,
    required int orderIndex,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/admin/lessons'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'lectureText': lectureText,
        'level': level,
        'orderIndex': orderIndex,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final data = decoded['lesson'] ?? decoded['data'] ?? decoded;
      return _LessonItem.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Қате жауап форматы');
  }

  Future<_LessonItem> updateLesson({
    required int id,
    String? title,
    String? description,
    String? lectureText,
    String? level,
    int? orderIndex,
    bool? isArchived,
  }) async {
    final Map<String, dynamic> body = {};

    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (lectureText != null) body['lectureText'] = lectureText;
    if (level != null) body['level'] = level;
    if (orderIndex != null) body['orderIndex'] = orderIndex;
    if (isArchived != null) body['isArchived'] = isArchived;

    final response = await http.patch(
      Uri.parse('$_baseUrl/api/admin/lessons/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final data = decoded['lesson'] ?? decoded['data'] ?? decoded;
      return _LessonItem.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Қате жауап форматы');
  }

  Future<void> archiveLesson(int lessonId, bool isArchived) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/admin/lessons/$lessonId/archive'),
      headers: await _headers(),
      body: jsonEncode({
        'isArchived': isArchived,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }
  }
}