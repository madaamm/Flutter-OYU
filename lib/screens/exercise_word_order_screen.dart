import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/task_model.dart';
import 'package:kazakh_learning_app/services/lesson_service.dart';

class ExerciseTaskSelectScreen extends StatefulWidget {
  final int lessonId;
  final int lessonNumber;
  final String lessonTitle;
  final String level;

  const ExerciseTaskSelectScreen({
    super.key,
    required this.lessonId,
    required this.lessonNumber,
    required this.lessonTitle,
    required this.level,
  });

  @override
  State<ExerciseTaskSelectScreen> createState() =>
      _ExerciseTaskSelectScreenState();
}

class _ExerciseTaskSelectScreenState extends State<ExerciseTaskSelectScreen> {
  static const Color purple = Color(0xFF6A00FF);
  static const Color bg = Color(0xFFFDF8FF);

  final LessonService _lessonService = LessonService();

  late Future<List<TaskModel>> _futureTasks;

  @override
  void initState() {
    super.initState();
    _futureTasks = _loadPlayableTasks();
  }

  Future<List<TaskModel>> _loadPlayableTasks() async {
    final tasks = await _lessonService.getLessonTasks(widget.lessonId);

    final playable = tasks.where((task) {
      if (task.type == 'SENTENCE_BUILD') {
        return task.correctWords.isNotEmpty;
      }

      if (task.type == 'WORD_MATCH') {
        return task.matchingPairs.isNotEmpty;
      }

      return false;
    }).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return playable;
  }

  Future<void> _reload() async {
    setState(() {
      _futureTasks = _loadPlayableTasks();
    });

    await _futureTasks;
  }

  Future<void> _openTask(TaskModel task) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseWordOrderScreen(
          lessonId: widget.lessonId,
          lessonNumber: widget.lessonNumber,
          lessonTitle: widget.lessonTitle,
          level: widget.level,
          task: task,
        ),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: purple,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.lessonTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: FutureBuilder<List<TaskModel>>(
                  future: _futureTasks,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: purple),
                      );
                    }

                    if (snapshot.hasError) {
                      return _SelectMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Тапсырмалар жүктелмеді',
                        message: '${snapshot.error}',
                        buttonText: 'Қайта көру',
                        onTap: _reload,
                      );
                    }

                    final tasks = snapshot.data ?? [];

                    if (tasks.isEmpty) {
                      return _SelectMessage(
                        icon: Icons.assignment_outlined,
                        title: 'Exercise жоқ',
                        message:
                        'Бұл сабаққа әзірге sentence build немесе word match тапсырмасы қосылмаған',
                        buttonText: 'Артқа қайту',
                        onTap: () => Navigator.pop(context, true),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final task = tasks[index];

                          return _UserTaskCard(
                            task: task,
                            number: index + 1,
                            onTap: () => _openTask(task),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTaskCard extends StatelessWidget {
  final TaskModel task;
  final int number;
  final VoidCallback onTap;

  const _UserTaskCard({
    required this.task,
    required this.number,
    required this.onTap,
  });

  static const Color purple = Color(0xFF6A00FF);

  String get _title {
    if (task.type == 'SENTENCE_BUILD') {
      return task.promptText.trim().isNotEmpty
          ? task.promptText.trim()
          : 'Sentence build';
    }

    if (task.type == 'WORD_MATCH') {
      return 'Word match';
    }

    return 'Task';
  }

  IconData get _icon {
    if (task.type == 'WORD_MATCH') return Icons.compare_arrows_rounded;
    return Icons.extension_rounded;
  }

  String get _typeLabel {
    if (task.type == 'WORD_MATCH') return 'Word match';
    return 'Sentence build';
  }

  int get _itemsCount {
    if (task.type == 'WORD_MATCH') return task.matchingPairs.length;
    return task.optionsWords.length;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE4D2FF),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: purple.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8E2BFF),
                      Color(0xFF4E0497),
                    ],
                  ),
                ),
                child: Icon(
                  _icon,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: purple,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${task.promptLang} → ${task.targetLang}',
                      style: const TextStyle(
                        color: Color(0xFF9A9A9A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TaskTag(text: _typeLabel),
                        _TaskTag(text: 'XP: ${task.xpReward}'),
                        _TaskTag(text: 'Order: ${task.orderIndex}'),
                        if (_itemsCount > 0) _TaskTag(text: 'Items: $_itemsCount'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.play_circle_fill_rounded,
                color: purple,
                size: 38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTag extends StatelessWidget {
  final String text;

  const _TaskTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E8FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6A00FF),
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SelectMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onTap;

  const _SelectMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF6A00FF), size: 70),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A00FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ExerciseStage { building, correct, wrong, reward }

class ExerciseWordOrderScreen extends StatefulWidget {
  final int lessonId;
  final int lessonNumber;
  final String lessonTitle;
  final String level;
  final TaskModel task;

  const ExerciseWordOrderScreen({
    super.key,
    required this.lessonId,
    required this.lessonNumber,
    required this.lessonTitle,
    required this.level,
    required this.task,
  });

  @override
  State<ExerciseWordOrderScreen> createState() =>
      _ExerciseWordOrderScreenState();
}

class _ExerciseWordOrderScreenState extends State<ExerciseWordOrderScreen> {
  static const Color purple = Color(0xFF6A00FF);
  static const Color green = Color(0xFF34C759);
  static const Color red = Color(0xFFFF4B4B);
  static const Color bg = Color(0xFFFDF8FF);
  final LessonService _lessonService = LessonService();

  int _lives = 3;

  List<String> _slots = [];
  List<String> _bank = [];

  List<MatchingPair> _leftPairs = [];
  List<MatchingPair> _rightPairs = [];
  int? _selectedLeftId;
  int? _selectedRightId;
  final Map<int, int> _matchedIds = {};
  bool _submittingAnswer = false;
  bool _alreadyCompletedTask = false;
  int _earnedXp = 0;

  _ExerciseStage _stage = _ExerciseStage.building;

  TaskModel get _task => widget.task;

  bool get _isSentenceBuild => _task.type == 'SENTENCE_BUILD';

  bool get _isWordMatch => _task.type == 'WORD_MATCH';

  @override
  void initState() {
    super.initState();
    _setupTask();
  }

  List<String> _cleanWords(List<String> words) {
    return words
        .expand((item) => item.replaceAll(',', ' ').split(RegExp(r'\\s+')))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<T> _shuffled<T>(List<T> items) {
    final result = [...items];
    result.shuffle(math.Random());
    return result;
  }

  void _setupTask() {
    _stage = _ExerciseStage.building;

    _slots = [];
    _bank = [];

    _leftPairs = [];
    _rightPairs = [];
    _selectedLeftId = null;
    _selectedRightId = null;
    _matchedIds.clear();

    if (_isSentenceBuild) {
      final correct = _cleanWords(_task.correctWords);
      final options = _cleanWords(
        _task.optionsWords.isNotEmpty ? _task.optionsWords : _task.correctWords,
      );

      _bank = options.isNotEmpty ? [...options] : [...correct];
      return;
    }

    if (_isWordMatch) {
      _leftPairs = [..._task.matchingPairs];
      _rightPairs = _shuffled(_task.matchingPairs);
    }
  }

  void _placeWord(int index) {
    if (_stage != _ExerciseStage.building) return;
    if (!_isSentenceBuild) return;
    if (index < 0 || index >= _bank.length) return;

    setState(() {
      _slots.add(_bank[index]);
      _bank.removeAt(index);
    });
  }

  void _removeWord(int index) {
    if (_stage != _ExerciseStage.building) return;
    if (!_isSentenceBuild) return;
    if (index < 0 || index >= _slots.length) return;

    setState(() {
      _bank.add(_slots[index]);
      _slots.removeAt(index);
    });
  }

  void _selectLeft(int id) {
    if (_stage != _ExerciseStage.building) return;

    setState(() {
      if (_selectedLeftId == id) {
        _selectedLeftId = null;
      } else {
        _selectedLeftId = id;
      }
    });

    _tryMatch();
  }

  void _selectRight(int id) {
    if (_stage != _ExerciseStage.building) return;

    setState(() {
      if (_selectedRightId == id) {
        _selectedRightId = null;
      } else {
        _selectedRightId = id;
      }
    });

    _tryMatch();
  }

  void _tryMatch() {
    final leftId = _selectedLeftId;
    final rightId = _selectedRightId;

    if (leftId == null || rightId == null) return;

    setState(() {
      final previousLeftForRight = _matchedIds.entries
          .where((entry) => entry.value == rightId && entry.key != leftId)
          .map((entry) => entry.key)
          .toList();

      for (final previousLeftId in previousLeftForRight) {
        _matchedIds.remove(previousLeftId);
      }

      _matchedIds[leftId] = rightId;

      _selectedLeftId = null;
      _selectedRightId = null;
    });
  }

  bool get _canCheck {
    if (_stage != _ExerciseStage.building) return false;

    if (_isSentenceBuild) {
      return _slots.isNotEmpty;
    }

    if (_isWordMatch) {
      return _matchedIds.length == _task.matchingPairs.length;
    }

    return false;
  }

  List<Map<String, String>> _buildAnswerPairs() {
    return _matchedIds.entries
        .map(
          (entry) => {
            'leftId': entry.key.toString(),
            'rightId': entry.value.toString(),
          },
        )
        .toList();
  }

  Future<Map<String, dynamic>> _submitCorrectAnswer() async {
    if (_isSentenceBuild) {
      return _lessonService.submitTaskAnswer(
        taskId: _task.id,
        answerWords: _slots,
      );
    }

    if (_isWordMatch) {
      return _lessonService.submitTaskAnswer(
        taskId: _task.id,
        answerPairs: _buildAnswerPairs(),
      );
    }

    return <String, dynamic>{};
  }

  String _normalize(String word) {
    return word.trim().toLowerCase().replaceAll(RegExp(r'[.,!?]'), '');
  }

  bool _isCorrectAnswer() {
    if (_isSentenceBuild) {
      final correct = _cleanWords(_task.correctWords);

      if (_slots.length != correct.length) return false;

      for (int i = 0; i < correct.length; i++) {
        if (_normalize(_slots[i]) != _normalize(correct[i])) {
          return false;
        }
      }

      return true;
    }

    if (_isWordMatch) {
      if (_matchedIds.length != _task.matchingPairs.length) {
        return false;
      }

      for (final pair in _task.matchingPairs) {
        if (_matchedIds[pair.id] != pair.id) {
          return false;
        }
      }

      return true;
    }

    return false;
  }

  Future<void> _handleCheck() async {
    if (!_canCheck || _submittingAnswer) return;

    if (_isCorrectAnswer()) {
      setState(() {
        _submittingAnswer = true;
        _stage = _ExerciseStage.correct;
      });

      try {
        final result = await _submitCorrectAnswer();

        _alreadyCompletedTask = result['alreadySubmitted'] == true;
        _earnedXp = result['earnedXp'] is int
            ? result['earnedXp'] as int
            : int.tryParse('${result['earnedXp'] ?? 0}') ?? 0;

        await Future<void>.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        setState(() {
          _stage = _ExerciseStage.reward;
        });
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _submittingAnswer = false;
          });
        }
      }
      return;
    }

    setState(() {
      _lives = math.max(0, _lives - 1);
      _stage = _ExerciseStage.wrong;
    });

    if (_lives > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 850));

      if (!mounted) return;

      setState(() {
        _setupTask();
      });
    }
  }

  void _handleRewardGet() {
    Navigator.pop(context, true);
  }

  void _restartTask() {
    setState(() {
      _lives = 3;
      _submittingAnswer = false;
      _alreadyCompletedTask = false;
      _earnedXp = 0;
      _setupTask();
    });
  }

  Color _buttonColor() {
    if (_stage == _ExerciseStage.correct) return green;
    if (_stage == _ExerciseStage.wrong && _lives == 0) return red;
    if (_canCheck) return green;
    return const Color(0xFFE9E2EE);
  }

  Color _buttonTextColor() {
    if (_stage == _ExerciseStage.correct ||
        _stage == _ExerciseStage.wrong ||
        _canCheck) {
      return Colors.white;
    }

    return const Color(0xFF7B5BB0);
  }

  VoidCallback? _buttonAction() {
    if (_stage == _ExerciseStage.correct) return null;

    if (_stage == _ExerciseStage.wrong && _lives == 0) {
      return () => Navigator.pop(context, true);
    }

    if (_canCheck && !_submittingAnswer) return _handleCheck;

    return null;
  }

  String _promptText() {
    if (_isSentenceBuild) {
      return _task.promptText.trim().isNotEmpty
          ? _task.promptText.trim()
          : 'Put the words in correct order';
    }

    if (_isWordMatch) {
      return 'Match the words';
    }

    return 'Exercise';
  }

  String _wrongAnswerText() {
    if (_isSentenceBuild) {
      return 'Wrong. Correct answer: ${_cleanWords(_task.correctWords).join(' ')}';
    }

    if (_isWordMatch) {
      final correct = _task.matchingPairs
          .map((pair) => '${pair.left} — ${pair.right}')
          .join(', ');
      return 'Wrong. Correct pairs: $correct';
    }

    return 'Wrong answer';
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _ExerciseStage.reward) {
      return _RewardScreen(
        xp: _earnedXp > 0 ? _earnedXp : _task.xpReward,
        alreadyCompleted: _alreadyCompletedTask,
        onGet: _handleRewardGet,
        onClose: () => Navigator.pop(context, true),
        onRestart: _restartTask,
      );
    }

    final isWrong = _stage == _ExerciseStage.wrong;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _ExerciseHeader(
            lives: _lives,
            onClose: () => Navigator.pop(context, true),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 46, 28, 22),
              children: [
                Center(
                  child: _PromptBubble(text: _promptText()),
                ),
                const SizedBox(height: 58),
                if (_isSentenceBuild) ...[
                  _AnswerBox(
                    words: _slots,
                    isWrong: isWrong,
                    onTapWord: _removeWord,
                  ),
                  const SizedBox(height: 36),
                  _WordBank(
                    words: _bank,
                    isLocked: isWrong,
                    onTapWord: _placeWord,
                  ),
                ],
                if (_isWordMatch) ...[
                  _WordMatchBoard(
                    leftPairs: _leftPairs,
                    rightPairs: _rightPairs,
                    selectedLeftId: _selectedLeftId,
                    selectedRightId: _selectedRightId,
                    matchedIds: _matchedIds,
                    stage: _stage,
                    isLocked: isWrong || _stage == _ExerciseStage.correct,
                    onTapLeft: _selectLeft,
                    onTapRight: _selectRight,
                  ),
                ],
                if (isWrong) ...[
                  const SizedBox(height: 28),
                  _FeedbackBox(
                    message: _wrongAnswerText(),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(38, 10, 38, 34),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _buttonAction(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonColor(),
                  disabledBackgroundColor: const Color(0xFFE9E2EE),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF7B5BB0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  _stage == _ExerciseStage.wrong && _lives == 0
                      ? 'Finish'
                      : _stage == _ExerciseStage.correct
                          ? 'Correct!'
                      : _submittingAnswer
                          ? 'Saving...'
                          : 'Check',
                  style: TextStyle(
                    color: _buttonTextColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
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

class _ExerciseHeader extends StatelessWidget {
  final int lives;
  final VoidCallback onClose;

  const _ExerciseHeader({
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
        constraints: const BoxConstraints(minWidth: 230, maxWidth: 430),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 22,
            fontWeight: FontWeight.w900,
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
      ..moveTo(48, size.height - 4)
      ..lineTo(0, size.height + 34)
      ..lineTo(4, size.height - 42)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnswerBox extends StatelessWidget {
  final List<String> words;
  final bool isWrong;
  final void Function(int index) onTapWord;

  const _AnswerBox({
    required this.words,
    required this.isWrong,
    required this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
    isWrong ? const Color(0xFFFF4B4B) : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 188),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: words.isEmpty
          ? const Align(
        alignment: Alignment.topLeft,
        child: Text(
          'Tap words below',
          style: TextStyle(
            color: Color(0xFF9C9C9C),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      )
          : Wrap(
        spacing: 18,
        runSpacing: 18,
        children: List.generate(words.length, (i) {
          return _WordPill(
            word: words[i],
            isWrong: isWrong,
            onTap: isWrong ? null : () => onTapWord(i),
          );
        }),
      ),
    );
  }
}

class _WordBank extends StatelessWidget {
  final List<String> words;
  final bool isLocked;
  final void Function(int index) onTapWord;

  const _WordBank({
    required this.words,
    required this.isLocked,
    required this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 22,
      runSpacing: 22,
      alignment: WrapAlignment.start,
      children: List.generate(words.length, (i) {
        return _WordPill(
          word: words[i],
          isWrong: false,
          onTap: isLocked ? null : () => onTapWord(i),
        );
      }),
    );
  }
}

class _WordPill extends StatelessWidget {
  final String word;
  final bool isWrong;
  final VoidCallback? onTap;

  const _WordPill({
    required this.word,
    required this.isWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
    isWrong ? const Color(0xFFFF4B4B) : const Color(0xFF6A00FF);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.16),
              blurRadius: 9,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          word,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _WordMatchBoard extends StatelessWidget {
  final List<MatchingPair> leftPairs;
  final List<MatchingPair> rightPairs;
  final int? selectedLeftId;
  final int? selectedRightId;
  final Map<int, int> matchedIds;
  final _ExerciseStage stage;
  final bool isLocked;
  final void Function(int id) onTapLeft;
  final void Function(int id) onTapRight;

  const _WordMatchBoard({
    required this.leftPairs,
    required this.rightPairs,
    required this.selectedLeftId,
    required this.selectedRightId,
    required this.matchedIds,
    required this.stage,
    required this.isLocked,
    required this.onTapLeft,
    required this.onTapRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftPairs.map((pair) {
                final matched = matchedIds.containsKey(pair.id);
                final selected = selectedLeftId == pair.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _MatchCard(
                    text: pair.left,
                    selected: selected,
                    matched: matched,
                    stage: stage,
                    disabled: isLocked,
                    onTap: () => onTapLeft(pair.id),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: rightPairs.map((pair) {
                final matched = matchedIds.containsValue(pair.id);
                final selected = selectedRightId == pair.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _MatchCard(
                    text: pair.right,
                    selected: selected,
                    matched: matched,
                    stage: stage,
                    disabled: isLocked,
                    onTap: () => onTapRight(pair.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String text;
  final bool selected;
  final bool matched;
  final _ExerciseStage stage;
  final bool disabled;
  final VoidCallback onTap;

  const _MatchCard({
    required this.text,
    required this.selected,
    required this.matched,
    required this.stage,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = selected || matched;
    final borderColor = stage == _ExerciseStage.correct
        ? const Color(0xFF34C759)
        : stage == _ExerciseStage.wrong
            ? const Color(0xFFFF4B4B)
            : isHighlighted
                ? const Color(0xFFFFC400)
                : const Color(0xFF6A00FF);
    final backgroundColor = stage == _ExerciseStage.correct
        ? const Color(0xFFEFFFF3)
        : stage == _ExerciseStage.wrong
            ? const Color(0xFFFFEFEF)
            : isHighlighted
                ? const Color(0xFFFFF7DA)
                : Colors.white;

    return Opacity(
      opacity: disabled && !matched ? 0.6 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.15),
                blurRadius: 9,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  final String message;

  const _FeedbackBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF4B4B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '😅',
            style: TextStyle(fontSize: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardScreen extends StatelessWidget {
  final int xp;
  final bool alreadyCompleted;
  final VoidCallback onGet;
  final VoidCallback onClose;
  final VoidCallback onRestart;

  const _RewardScreen({
    required this.xp,
    required this.alreadyCompleted,
    required this.onGet,
    required this.onClose,
    required this.onRestart,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                const Spacer(),
                Image.asset(
                  'assets/images/Oyu.png',
                  height: 165,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 26),
                Text(
                  alreadyCompleted
                      ? 'You already completed this task'
                      : 'You did great job',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  alreadyCompleted
                      ? 'No additional rewards are given for repeated completion'
                      : 'Task finished',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE8D9FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                if (!alreadyCompleted)
                  Container(
                    width: 250,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
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
                if (alreadyCompleted)
                  Container(
                    width: 280,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Task already passed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onGet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRestart,
                  child: const Text(
                    'Try again',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
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
