import 'package:flutter/material.dart';

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

  // ✅ assets
  static const String kOyuHappy = "assets/images/Oyu.png";
  static const String kOyuSleep = "assets/images/Oyu_uyktauda.png";

  // ✅ lesson demo (кейін backend/json-ға ауыстырасың)
  final String promptEn = "I drink water";
  final List<String> correct = const ["Men", "su", "ishemin"];
  final List<String> pool = ["oqiymyn", "ishemin", "Men", "su", "nan"];

  // answer slots: 3 орын
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

  List<String> get _availableWords =>
      pool.where((w) => !_isPlaced(w)).toList(growable: false);

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
      setState(() {
        lives = (lives - 1).clamp(0, 3);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error 😅 Try again!")),
      );
    }
  }

  void _continue() {
    Navigator.pop(context);
  }

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
            // ===== Top bar =====
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
                    // ===== Main content =====
                    ListView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                      children: [
                        _SpeechTop(text: promptEn),

                        const SizedBox(height: 20),

                        // Answer slots (3)
                        _AnswerLine(
                          words: slots,
                          correctWords: correct,
                          showCorrectStyle: isCorrect,
                          onTapSlot: _removeFromSlot,
                        ),

                        const SizedBox(height: 24),

                        // Word bank
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

                        // Oyu + speech
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

                    // ===== Bottom button =====
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isCorrect
                              ? _continue
                              : (_allFilled ? _check : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            isCorrect ? green : (_allFilled ? green : Colors.grey.shade400),
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

// ---------- UI parts ----------

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
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  final List<String?> words; // length 3
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

        // 3 lines under (like notebook)
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
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
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
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}