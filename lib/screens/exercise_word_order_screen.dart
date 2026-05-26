import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/task_model.dart';
import 'package:kazakh_learning_app/services/lesson_service.dart';

class ExerciseWordOrderScreen extends StatefulWidget {
  final int lessonId;
  final int lessonNumber;
  final String lessonTitle;
  final String level;

  const ExerciseWordOrderScreen({
    super.key,
    required this.lessonId,
    required this.lessonNumber,
    required this.lessonTitle,
    required this.level,
  });

  @override
  State<ExerciseWordOrderScreen> createState() =>
      _ExerciseWordOrderScreenState();
}

enum _ExerciseStage { building, correct, wrong, finished }

class _ExerciseWordOrderScreenState extends State<ExerciseWordOrderScreen> {
  static const Color purple = Color(0xFF6A00FF);
  static const Color green = Color(0xFF34C759);
  static const Color bg = Color(0xFFFDF8FF);

  final LessonService _lessonService = LessonService();

  bool _loading = true;
  String? _error;

  List<TaskModel> _tasks = [];
  int _currentTaskIndex = 0;
  int _lives = 3;
  int _earnedXp = 0;

  List<String> _slots = [];
  List<String> _bank = [];

  _ExerciseStage _stage = _ExerciseStage.building;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _lessonService.getLessonTasks(widget.lessonId);

      if (!mounted) return;

      setState(() {
        _tasks =
            tasks.where((t) => _cleanWords(t.correctWords).isNotEmpty).toList();
        _loading = false;

        if (_tasks.isNotEmpty) {
          _setupTask(_tasks.first);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  TaskModel get _currentTask => _tasks[_currentTaskIndex];

  List<String> _cleanWords(List<String> words) {
    return words
        .expand((item) => item.replaceAll(',', ' ').split(RegExp(r'\s+')))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _setupTask(TaskModel task) {
    final correct = _cleanWords(task.correctWords);
    final options = _cleanWords(
      task.optionsWords.isNotEmpty ? task.optionsWords : task.correctWords,
    );

    _slots = [];
    _bank = options.isNotEmpty ? [...options] : [...correct];
    _stage = _ExerciseStage.building;
  }

  void _placeWord(int index) {
    if (_stage != _ExerciseStage.building) return;

    setState(() {
      _slots.add(_bank[index]);
      _bank.removeAt(index);
    });
  }

  void _removeWord(int index) {
    if (_stage != _ExerciseStage.building) return;

    setState(() {
      _bank.add(_slots[index]);
      _slots.removeAt(index);
    });
  }

  bool get _canCheck {
    return _stage == _ExerciseStage.building && _slots.isNotEmpty;
  }

  String _normalize(String word) {
    return word
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.,!?]'), '');
  }

  bool _isCorrectAnswer() {
    final correct = _cleanWords(_currentTask.correctWords);

    if (_slots.length != correct.length) return false;

    for (int i = 0; i < correct.length; i++) {
      if (_normalize(_slots[i]) != _normalize(correct[i])) {
        return false;
      }
    }

    return true;
  }

  Future<void> _handleButton() async {
    if (_stage == _ExerciseStage.correct) {
      _goNext();
      return;
    }

    if (_stage == _ExerciseStage.wrong && _lives == 0) {
      setState(() => _stage = _ExerciseStage.finished);
      return;
    }

    if (!_canCheck) return;

    try {
      await _lessonService.submitTaskAnswer(
        taskId: _currentTask.id,
        answerWords: _slots,
      );
    } catch (e) {
      debugPrint('Submit answer error: $e');
    }

    if (_isCorrectAnswer()) {
      setState(() {
        _earnedXp += _currentTask.xpReward;
        _stage = _ExerciseStage.correct;
      });
      return;
    }

    setState(() {
      _lives = math.max(0, _lives - 1);
      _stage = _ExerciseStage.wrong;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    if (_lives > 0) {
      setState(() {
        _slots = [];
        _bank = _cleanWords(
          _currentTask.optionsWords.isNotEmpty
              ? _currentTask.optionsWords
              : _currentTask.correctWords,
        );
        _stage = _ExerciseStage.building;
      });
    }
  }

  void _goNext() {
    if (_currentTaskIndex < _tasks.length - 1) {
      setState(() {
        _currentTaskIndex++;
        _setupTask(_tasks[_currentTaskIndex]);
      });
    } else {
      setState(() => _stage = _ExerciseStage.finished);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: purple)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: Text(_error!)),
      );
    }

    if (_tasks.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No exercises'),
          ),
        ),
      );
    }

    if (_stage == _ExerciseStage.finished) {
      return _FinishedScreen(
        xp: _earnedXp,
        onClose: () => Navigator.pop(context, true),
      );
    }

    final prompt = _currentTask.promptText.trim().isNotEmpty
        ? _currentTask.promptText.trim()
        : 'Put the words in correct order';

    final isCorrect = _stage == _ExerciseStage.correct;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _Header(
            lives: _lives,
            onClose: () => Navigator.pop(context),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 34, 28, 20),
              children: [
                Center(
                  child: _PromptBubble(text: prompt),
                ),

                const SizedBox(height: 56),

                _AnswerBox(
                  words: _slots,
                  isCorrect: isCorrect,
                  onTapWord: _removeWord,
                ),

                const SizedBox(height: 34),

                _WordBank(
                  words: _bank,
                  isCorrect: isCorrect,
                  onTapWord: _placeWord,
                ),

                const SizedBox(height: 46),

                _MascotHint(isCorrect: isCorrect),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(38, 10, 38, 34),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed:
                (_canCheck || isCorrect || _stage == _ExerciseStage.wrong)
                    ? _handleButton
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  disabledBackgroundColor: const Color(0xFFE9E2EE),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF7B5BB0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  isCorrect ? 'Continue' : 'Check',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int lives;
  final VoidCallback onClose;

  const _Header({
    required this.lives,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 35,
        left: 34,
        right: 22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5B009E),
            Color(0xFF9618E0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (index) {
              final alive = index < lives;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  alive ? Icons.favorite : Icons.favorite_border,
                  color: alive
                      ? const Color(0xFFFF6B7A)
                      : Colors.white.withOpacity(0.35),
                  size: 36,
                ),
              );
            }),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }
}

class _PromptBubble extends StatelessWidget {
  final String text;

  const _PromptBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TopSpeechTailPainter(),
      child: Container(
        constraints: const BoxConstraints(minWidth: 230, maxWidth: 340),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TopSpeechTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(38, size.height - 4)
      ..lineTo(0, size.height + 28)
      ..lineTo(2, size.height - 35)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnswerBox extends StatelessWidget {
  final List<String> words;
  final bool isCorrect;
  final void Function(int index) onTapWord;

  const _AnswerBox({
    required this.words,
    required this.isCorrect,
    required this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        children: List.generate(words.length, (i) {
          return _WordPill(
            word: words[i],
            isCorrect: isCorrect,
            onTap: () => onTapWord(i),
          );
        }),
      ),
    );
  }
}

class _WordBank extends StatelessWidget {
  final List<String> words;
  final bool isCorrect;
  final void Function(int index) onTapWord;

  const _WordBank({
    required this.words,
    required this.isCorrect,
    required this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      alignment: WrapAlignment.start,
      children: List.generate(words.length, (i) {
        return _WordPill(
          word: words[i],
          isCorrect: false,
          onTap: isCorrect ? null : () => onTapWord(i),
        );
      }),
    );
  }
}

class _WordPill extends StatelessWidget {
  final String word;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _WordPill({
    required this.word,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
    isCorrect ? const Color(0xFF1E8E3E) : const Color(0xFF6A00FF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: borderColor,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.16),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          word,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MascotHint extends StatelessWidget {
  final bool isCorrect;

  const _MascotHint({
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6,
            bottom: 0,
            child: Image.asset(
              isCorrect
                  ? 'assets/images/Oyu.png'
                  : 'assets/images/Oyu_uyktauda.png',
              height: 170,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 165,
            right: 0,
            top: 28,
            child: CustomPaint(
              painter: _SpeechTailPainter(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFCFCFCF),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                      color: Colors.black.withOpacity(0.12),
                    ),
                  ],
                ),
                child: Text(
                  isCorrect
                      ? 'You did great job'
                      : 'Put the words in\ncorrect order',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFCFCFCF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(20, size.height - 10)
      ..quadraticBezierTo(-18, size.height + 26, -58, size.height + 38)
      ..quadraticBezierTo(-20, size.height + 5, 8, size.height - 34)
      ..close();

    canvas.drawPath(path.shift(const Offset(2, 3)), shadowPaint);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FinishedScreen extends StatelessWidget {
  final int xp;
  final VoidCallback onClose;

  const _FinishedScreen({
    required this.xp,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3B006E),
              Color(0xFF7B00D9),
              Color(0xFF3B006E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 34),
            child: Column(
              children: [
                const Spacer(),

                SizedBox(
                  height: 210,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Image.asset(
                          'assets/images/Oyu.png',
                          height: 155,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        left: 135,
                        right: 0,
                        top: 18,
                        child: CustomPaint(
                          painter: _RewardSpeechTailPainter(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.24),
                                  blurRadius: 16,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: const Text(
                              'You did great job',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'You will get',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: 240,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RewardItem(
                        image: 'assets/images/Sandyk.png',
                        value: '+1',
                        size: 64,
                      ),
                      _RewardItem(
                        image: 'assets/images/diamond.png',
                        value: '+$xp',
                        size: 62,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Get',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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
}

class _RewardItem extends StatelessWidget {
  final String image;
  final String value;
  final double size;

  const _RewardItem({
    required this.image,
    required this.value,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          image,
          height: size,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _RewardSpeechTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(35, size.height - 4)
      ..quadraticBezierTo(-10, size.height + 25, -45, size.height + 40)
      ..quadraticBezierTo(-14, size.height + 6, 12, size.height - 28)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}