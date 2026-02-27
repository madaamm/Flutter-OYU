import 'dart:math' as math;
import 'package:flutter/material.dart';

// ✅ Start exercise screen (төменде осы файлдың ішінде бар)
/// Егер сен бөлек файл жасағың келсе, кейін бөліп шығарамыз.

class AdminTaskScreen extends StatefulWidget {
  const AdminTaskScreen({super.key});

  @override
  State<AdminTaskScreen> createState() => _AdminTaskScreenState();
}

class _AdminTaskScreenState extends State<AdminTaskScreen> {
  static const String kOyuAsset = "assets/images/Oyu.png";
  static const String kEggAsset = "assets/images/Pink_egg.png";
  static const String kBoxAsset = "assets/images/Qorap.png";

  static const int kTasksPerCircle = 6;
  static const int kMaxCircles = 20;

  // ✅ backend жоқ кезде local тізім
  final List<int> _tasks = [];
  int _nextId = 1;

  void _add() {
    setState(() {
      final maxTotal = kMaxCircles * kTasksPerCircle;
      if (_tasks.length < maxTotal) _tasks.add(_nextId++);
    });
  }

  void _deleteTask(int globalIndex) {
    if (globalIndex < 0 || globalIndex >= _tasks.length) return;
    setState(() => _tasks.removeAt(globalIndex));
  }

  void _openTaskSheet({required int globalIndex}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _TaskActionSheet(
          subtitle: "Say where people are from",
          lessonNumber: globalIndex + 1,
          onDelete: () {
            Navigator.pop(context);
            _deleteTask(globalIndex);
          },
          onOpenTheory: (level) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TheoryLessonScreen(
                  lessonNumber: globalIndex + 1,
                  level: level,
                ),
              ),
            );
          },
          // ✅ NEW: Start exercise → ашу
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
    final totalTasks = _tasks.length;
    final circles =
    ((totalTasks + kTasksPerCircle - 1) ~/ kTasksPerCircle).clamp(1, kMaxCircles);

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
                      // ✅ Add button
                      Positioned(
                        right: 14,
                        top: 12,
                        child: ElevatedButton.icon(
                          onPressed: _add,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Добавить"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A0CA3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            minimumSize: const Size(0, 38),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),

                      // ✅ circles list
                      Positioned.fill(
                        top: 112,
                        child: ListView.builder(
                          padding: EdgeInsets.only(top: base * 0.01, bottom: base * 0.06),
                          itemCount: circles,
                          itemBuilder: (context, idx) {
                            final start = idx * kTasksPerCircle;
                            final filled = (totalTasks - start).clamp(0, kTasksPerCircle);
                            final showBox = filled == kTasksPerCircle;

                            return _CircleBlock(
                              base: base,
                              filledTasks: filled,
                              showBox: showBox,
                              eggAsset: kEggAsset,
                              oyuAsset: kOyuAsset,
                              boxAsset: kBoxAsset,
                              onTapTask: (taskIndexInCircle) {
                                final globalIndex = start + taskIndexInCircle;
                                if (globalIndex >= totalTasks) return;
                                _openTaskSheet(globalIndex: globalIndex);
                              },
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
  final int filledTasks; // 0..6
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
    final ringRadius = base * 0.26;
    final oyuSize = base * 0.42;
    final eggSize = base * 0.16;

    final blockH = base * 0.84;
    final center = Offset(base / 2, base * 0.38);

    return SizedBox(
      height: blockH,
      child: Stack(
        children: [
          // Center character
          Positioned(
            left: center.dx - oyuSize / 2,
            top: center.dy - oyuSize / 2,
            child: SizedBox(
              width: oyuSize,
              height: oyuSize,
              child: Image.asset(oyuAsset, fit: BoxFit.contain),
            ),
          ),

          // eggs
          for (int i = 0; i < filledTasks; i++)
            _eggOnRing(
              index: i,
              total: 6,
              center: center,
              radius: ringRadius,
              size: eggSize,
              eggAsset: eggAsset,
              onTap: () => onTapTask(i),
            ),

          // box after completed circle
          if (showBox)
            Positioned(
              left: base / 2 - (eggSize * 0.95) / 2,
              top: center.dy + ringRadius + eggSize * 0.45,
              child: Image.asset(
                boxAsset,
                width: eggSize * 0.95,
                height: eggSize * 0.95,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  Widget _eggOnRing({
    required int index,
    required int total,
    required Offset center,
    required double radius,
    required double size,
    required String eggAsset,
    required VoidCallback onTap,
  }) {
    final angle = (-math.pi / 2) + (2 * math.pi * index / total);
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: x - size / 2,
      top: y - size / 2,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: SizedBox(
            width: size,
            height: size,
            child: Image.asset(eggAsset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ================= Bottom Sheet =================

class _TaskActionSheet extends StatefulWidget {
  final String subtitle;
  final int lessonNumber;

  final VoidCallback onDelete;
  final void Function(String level) onOpenTheory;

  // ✅ NEW
  final void Function(String level) onOpenExercise;

  const _TaskActionSheet({
    required this.subtitle,
    required this.lessonNumber,
    required this.onDelete,
    required this.onOpenTheory,
    required this.onOpenExercise,
  });

  @override
  State<_TaskActionSheet> createState() => _TaskActionSheetState();
}

class _TaskActionSheetState extends State<_TaskActionSheet> {
  static const sheetPurple = Color(0xFF6A00FF);
  String level = "A1-A2";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                widget.subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),

              _whiteButton(
                text: "Theory",
                textColor: sheetPurple,
                onTap: () => widget.onOpenTheory(level),
              ),
              const SizedBox(height: 12),

              // ✅ Start exercise → экран ашылады
              _whiteButton(
                text: "Start exercise",
                textColor: const Color(0xFFFFB200),
                onTap: () => widget.onOpenExercise(level),
              ),
              const SizedBox(height: 12),

              Material(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: widget.onDelete,
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

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _levelPill("A1-A2")),
                  const SizedBox(width: 10),
                  Expanded(child: _levelPill("B1-B2")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelPill(String text) {
    final selected = level == text;
    return Material(
      color: selected ? Colors.white : Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => level = text),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? sheetPurple : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
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

// ================= Theory Screen =================

class TheoryLessonScreen extends StatelessWidget {
  final int lessonNumber;
  final String level;

  const TheoryLessonScreen({
    super.key,
    required this.lessonNumber,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6A00FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        title: Text("Theory Lesson $lessonNumber Level $level"),
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
                children: const [
                  Text(
                    "Word Order: SOV (Subject-Object-Verb)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Unlike English (SVO), Kazakh puts the verb at the end:\n\n"
                        "English: I drink water.\n\n"
                        "Kazakh: Men (I) + su (water) + ishemin (drink).\n"
                        "→ Men su ishemin.",
                    style: TextStyle(height: 1.45),
                  ),
                  SizedBox(height: 16),

                  Text(
                    "No Gender, No Articles",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text("• No \"he/she\" distinction: ол = he/she/it"),
                  SizedBox(height: 6),
                  Text("• No \"a/an/the\": kitap = a book / the book"),
                  SizedBox(height: 16),

                  Text(
                    "Plurals: Add -лар / -лер",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text("dost (friend) → dosttar (friends)"),
                  SizedBox(height: 6),
                  Text("ül (student) → ülder (students)"),
                  SizedBox(height: 10),
                  Text("(Choose -tar/-ter based on vowel harmony)"),
                  SizedBox(height: 18),

                  _CaseTable(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseTable extends StatelessWidget {
  const _CaseTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: const [
          _RowItem(left: "Case", right: "Ending", header: true),
          Divider(height: 1),
          _RowItem(left: "Nominative", right: "—"),
          Divider(height: 1),
          _RowItem(left: "Dative", right: "-ға/-ге"),
          Divider(height: 1),
          _RowItem(left: "Accusative", right: "-ды/-ді"),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String left;
  final String right;
  final bool header;

  const _RowItem({required this.left, required this.right, this.header = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: header ? FontWeight.w900 : FontWeight.w700,
      color: header ? Colors.black87 : Colors.black54,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(left, style: style)),
          Expanded(child: Text(right, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

// ================= Exercise Screen =================

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

  // ✅ assets (сен жіберген 2 сурет)
  static const String kOyuHappy = "assets/images/Oyu.png";
  static const String kOyuSleep = "assets/images/Oyu_uyktauda.png";

  final String promptEn = "I drink water";
  final List<String> correct = const ["Men", "su", "ishemin"];
  final List<String> pool = ["oqiymyn", "ishemin", "Men", "su", "nan"];

  late List<String?> slots; // 3 слот

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
            // Top purple bar
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
                              .map((w) => _WordChip(text: w, onTap: () => _placeWord(w)))
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
                                text: isCorrect ? "You did great job" : "Put the words in\ncorrect order",
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            isCorrect ? "Continue" : (_allFilled ? "Check" : "Continue"),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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

// ---------- UI widgets ----------

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
                      color: isCorrectChip ? const Color(0xFF2ECC71) : const Color(0xFF6A00FF).withOpacity(0.35),
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