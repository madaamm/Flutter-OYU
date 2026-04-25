import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/task_model.dart';
import 'package:kazakh_learning_app/services/lesson_service.dart';

class ExerciseWordOrderScreen extends StatefulWidget {
  final int lessonId;

  const ExerciseWordOrderScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<ExerciseWordOrderScreen> createState() =>
      _ExerciseWordOrderScreenState();
}

enum _Stage { building, correct, wrong }

class _ExerciseWordOrderScreenState extends State<ExerciseWordOrderScreen> {
  static const green = Color(0xFF58CC02);
  static const blue = Color(0xFF1899D6);
  static const red = Color(0xFFFF4B4B);
  static const bg = Color(0xFFF7F7F7);
  static const text = Color(0xFF2D2638);

  final LessonService _service = LessonService();

  List<TaskModel> tasks = [];
  int currentIndex = 0;
  int lives = 3;

  List<String> correctAnswer = [];
  List<String> slots = [];
  List<String> bank = [];

  _Stage stage = _Stage.building;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  List<String> _cleanWords(List<String> words) {
    return words
        .expand((item) => item.replaceAll(',', ' ').split(RegExp(r'\s+')))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _loadTasks() async {
    final data = await _service.getLessonTasks(widget.lessonId);

    if (!mounted) return;

    setState(() {
      tasks = data.where((t) {
        return _cleanWords(t.correctWords).isNotEmpty ||
            _cleanWords(t.optionsWords).isNotEmpty;
      }).toList();

      currentIndex = 0;
      lives = 3;

      if (tasks.isNotEmpty) {
        _setupTask(tasks.first);
      }
    });
  }

  void _setupTask(TaskModel task) {
    final cleanedCorrect = _cleanWords(task.correctWords);
    final cleanedOptions = _cleanWords(task.optionsWords);

    correctAnswer =
    cleanedCorrect.isNotEmpty ? cleanedCorrect : cleanedOptions;

    slots = [];
    bank = cleanedOptions.isNotEmpty
        ? List<String>.from(cleanedOptions)
        : List<String>.from(correctAnswer);

    stage = _Stage.building;

    print('correctAnswer: $correctAnswer');
    print('correctAnswer length: ${correctAnswer.length}');
    print('bank: $bank');
  }

  TaskModel get currentTask => tasks[currentIndex];
  bool get canCheck {
    return stage == _Stage.building && slots.length >= 1 && slots.length <= 5;
  }

  double get progress => tasks.isEmpty ? 0 : currentIndex / tasks.length;

  void _placeWord(int index) {
    if (stage != _Stage.building) return;
    if (index < 0 || index >= bank.length) return;

    setState(() {
      slots.add(bank[index]);
      bank.removeAt(index);
    });
  }

  void _removeWord(int index) {
    if (stage != _Stage.building) return;
    if (index < 0 || index >= slots.length) return;

    setState(() {
      bank.add(slots[index]);
      slots.removeAt(index);
    });
  }

  void _check() {
    if (!canCheck) return;

    final isRight = _listEquals(slots, correctAnswer);

    if (isRight) {
      setState(() => stage = _Stage.correct);
    } else {
      setState(() {
        lives = (lives - 1).clamp(0, 3);
        stage = _Stage.wrong;
      });

      if (lives > 0) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;

          if (stage == _Stage.wrong) {
            setState(() {
              slots = [];
              bank = _cleanWords(
                currentTask.optionsWords.isNotEmpty
                    ? currentTask.optionsWords
                    : currentTask.correctWords,
              );
              stage = _Stage.building;
            });
          }
        });
      }
    }
  }

  void _continue() {
    if (currentIndex < tasks.length - 1) {
      setState(() {
        currentIndex++;
        _setupTask(tasks[currentIndex]);
      });
    } else {
      _showFinished();
    }
  }

  void _showFinished() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🏆", style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              "Урок завершён!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text("Жарайсың! Молодец!"),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Готово",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i].trim() != b[i].trim()) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isCorrect = stage == _Stage.correct;
    final isWrong = stage == _Stage.wrong;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _Header(
                lives: lives,
                progress: progress,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ПЕРЕВЕДИТЕ ЭТО ПРЕДЛОЖЕНИЕ",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  currentTask.promptText,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: text,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 86),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFFF0FFF0)
                      : isWrong
                      ? const Color(0xFFFFF0F0)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isCorrect
                        ? green
                        : isWrong
                        ? red
                        : Colors.black26,
                    width: isCorrect || isWrong ? 2 : 1.6,
                  ),
                ),
                child: slots.isEmpty
                    ? const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Выберите слова ниже",
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 14,
                    ),
                  ),
                )
                    : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(slots.length, (index) {
                    return _WordChip(
                      word: slots[index],
                      color: isCorrect ? green : text,
                      borderColor: isCorrect ? green : Colors.black26,
                      onTap:
                      isCorrect ? null : () => _removeWord(index),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              Container(height: 1.5, color: Colors.black12),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(bank.length, (index) {
                  return _WordChip(
                    word: bank[index],
                    color: blue,
                    borderColor: blue,
                    onTap: () => _placeWord(index),
                  );
                }),
              ),
              const Spacer(),
              if (isCorrect || isWrong)
                _FeedbackBox(
                  correct: isCorrect,
                  title: isCorrect ? "Дұрыс жауап!" : "Жауап қате",
                  subtitle: isCorrect
                      ? "Отличная работа!"
                      : lives == 0
                      ? "Правильно: ${correctAnswer.join(' ')}"
                      : "Попробуй ещё раз",
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: isCorrect || lives == 0
                      ? _continue
                      : canCheck
                      ? _check
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isWrong && lives > 0 ? red : green,
                    disabledBackgroundColor: bg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isCorrect || lives == 0
                        ? currentIndex < tasks.length - 1
                        ? "Продолжить"
                        : "Завершить"
                        : "Проверить",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: canCheck || isCorrect || lives == 0
                          ? Colors.white
                          : Colors.black45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int lives;
  final double progress;
  final VoidCallback onClose;

  const _Header({
    required this.lives,
    required this.progress,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(3, (index) {
            return Text(
              index < lives ? "♥" : "♡",
              style: const TextStyle(
                color: Color(0xFFFF4B4B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          }),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 16,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF58CC02)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, color: Colors.black45, size: 26),
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  const _WordChip({
    required this.word,
    required this.color,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Text(
            word,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  final bool correct;
  final String title;
  final String subtitle;

  const _FeedbackBox({
    required this.correct,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: correct ? const Color(0xFFF0FFF0) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: correct ? const Color(0xFF58CC02) : const Color(0xFFFF4B4B),
        ),
      ),
      child: Row(
        children: [
          Text(correct ? "🎉" : "😅", style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2638),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}