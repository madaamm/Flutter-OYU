import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/lesson_model.dart';
import 'package:kazakh_learning_app/models/task_model.dart';
import 'package:kazakh_learning_app/screens/alphabet_screen.dart';
import 'package:kazakh_learning_app/screens/ask_ai_screen.dart';
import 'package:kazakh_learning_app/screens/auth_screen.dart';
import 'package:kazakh_learning_app/screens/game_zone_screen.dart';
import 'package:kazakh_learning_app/screens/profile_screen.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/services/lesson_service.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color purple = Color(0xFF6F19D9);

  int currentIndex = 0;
  final _auth = AuthService();
  String _name = 'User';
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _name = widget.userName.trim().isEmpty ? 'User' : widget.userName.trim();
    pages = _buildPages();
    _bootstrap();
  }

  List<Widget> _buildPages() {
    return [
      HomePage(userName: _name),
      const AlphabetScreen(),
      const AskAiScreen(),
      const GameZoneScreen(),
      ProfileScreen(userName: _name),
    ];
  }

  Future<void> _bootstrap() async {
    await _loadNameFromCache();
    await _refreshMeSilently();
  }

  Future<void> _loadNameFromCache() async {
    final cached = await _auth.getCachedUsernameOrDefault();
    if (!mounted) return;

    if (cached.trim().isNotEmpty && cached.trim() != _name.trim()) {
      setState(() {
        _name = cached.trim();
        pages = _buildPages();
      });
    }
  }

  Future<void> _refreshMeSilently() async {
    try {
      await _auth.me();
      await _loadNameFromCache();
    } catch (_) {}
  }

  Future<void> _onTabChanged(int index) async {
    setState(() => currentIndex = index);
    await _loadNameFromCache();

    if (index == 4) {
      await _refreshMeSilently();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onTabChanged,
        selectedItemColor: purple,
        unselectedItemColor: const Color(0xFFA8A8A8),
        backgroundColor: const Color(0xFFF7F3FB),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0.5,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_fields_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: '',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color purple = Color(0xFF6F19D9);
  static const Color darkPurple = Color(0xFF4C0DB0);

  final _lessonService = LessonService();
  late Future<List<LessonModel>> _futureLessons;

  @override
  void initState() {
    super.initState();
    _futureLessons = _lessonService.getUserLessons();
  }

  Future<void> _refreshLessons() async {
    setState(() {
      _futureLessons = _lessonService.getUserLessons();
    });
    await _futureLessons;
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
    );
  }

  void _openLessonSheet(LessonModel lesson, int lessonNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _LessonActionSheet(
          title: lesson.title,
          level: lesson.level,
          onTheoryTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TheoryLessonScreen(
                  lessonNumber: lessonNumber,
                  level: lesson.level,
                  title: lesson.title,
                  description: lesson.description,
                  lectureText: lesson.lectureText,
                ),
              ),
            );
          },
          onExerciseTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciseWordOrderScreen(
                  lessonId: lesson.id,
                  lessonNumber: lessonNumber,
                  lessonTitle: lesson.title,
                  level: lesson.level,
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
      backgroundColor: purple,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(34),
              ),
              child: RefreshIndicator(
                onRefresh: _refreshLessons,
                child: FutureBuilder<List<LessonModel>>(
                  future: _futureLessons,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: purple),
                      );
                    }

                    if (snapshot.hasError) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.68,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.cloud_off_rounded,
                                      size: 58,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Уроктар жүктелмеді',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: purple,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${snapshot.error}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final lessons = snapshot.data ?? [];

                    if (lessons.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(
                            height: 650,
                            child: _EmptyLessonsState(),
                          ),
                        ],
                      );
                    }

                    final firstGroup = lessons.take(6).toList();

                    return LayoutBuilder(
                      builder: (context, c) {
                        final base = math.min(c.maxWidth, c.maxHeight);

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                          children: [
                            _LessonCircleGroup(
                              base: base,
                              lessons: firstGroup,
                              onTapLesson: (lesson, index) {
                                _openLessonSheet(lesson, index + 1);
                              },
                            ),
                            if (lessons.length > 6) ...[
                              const SizedBox(height: 12),
                              _LessonsVerticalList(
                                lessons: lessons.skip(6).toList(),
                                startNumber: 7,
                                onTapLesson: (lesson, number) {
                                  _openLessonSheet(lesson, number);
                                },
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 18,
        right: 18,
        bottom: 18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [purple, darkPurple],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          const _HeaderStat(
            icon: Icons.bolt_rounded,
            iconColor: Color(0xFFFFD54F),
            value: '3',
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 26,
            ),
            label: const Text(
              'Выйти',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCircleGroup extends StatelessWidget {
  final double base;
  final List<LessonModel> lessons;
  final void Function(LessonModel lesson, int index) onTapLesson;

  const _LessonCircleGroup({
    required this.base,
    required this.lessons,
    required this.onTapLesson,
  });

  @override
  Widget build(BuildContext context) {
    final double size = base * 0.95;
    final double eggSize = base * 0.15;
    final double oyuSize = base * 0.34;

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
                'assets/images/Oyu.png',
                width: oyuSize,
                fit: BoxFit.contain,
              ),
              for (int i = 0; i < lessons.length && i < 6; i++)
                _buildEggPosition(
                  lessons[i],
                  i,
                  eggSize,
                      () => onTapLesson(lessons[i], i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEggPosition(
      LessonModel lesson,
      int index,
      double size,
      VoidCallback onTap,
      ) {
    const positions = [
      Offset(0, -1.95),      // 1 - жоғары
      Offset(-1.55, -0.75),  // 2 - сол жақ
      Offset(1.55, -0.75),   // 3 - оң жақ
      Offset(-1.55, 0.95),   // 4
      Offset(1.55, 0.95),    // 5
      Offset(0, 2.0),        // 6 - төмен
    ];

    final pos = positions[index];

    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: Offset(pos.dx * size * 0.95, pos.dy * size * 0.95),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(size),
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Pink_egg.png',
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(
                      width: size * 0.62,
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonsVerticalList extends StatelessWidget {
  final List<LessonModel> lessons;
  final int startNumber;
  final void Function(LessonModel lesson, int number) onTapLesson;

  const _LessonsVerticalList({
    required this.lessons,
    required this.startNumber,
    required this.onTapLesson,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(lessons.length, (index) {
        final lesson = lessons[index];
        final number = startNumber + index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onTapLesson(lesson, number),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8DAFF)),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/Pink_egg.png',
                        width: 58,
                        height: 58,
                      ),
                      Text(
                        '$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4B2788),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lesson.level,
                    style: const TextStyle(
                      color: Color(0xFF6F19D9),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _LessonActionSheet extends StatelessWidget {
  final String title;
  final String level;
  final VoidCallback onTheoryTap;
  final VoidCallback onExerciseTap;

  const _LessonActionSheet({
    required this.title,
    required this.level,
    required this.onTheoryTap,
    required this.onExerciseTap,
  });

  static const Color purple = Color(0xFF7B1FE0);
  static const Color darkPurple = Color(0xFF5A0FAE);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [purple, darkPurple],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: purple.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (level.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  level,
                  style: const TextStyle(
                    color: Color(0xFFEBD9FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _PopupButton(
                text: 'Theory',
                textColor: purple,
                onTap: onTheoryTap,
              ),
              const SizedBox(height: 14),
              _PopupButton(
                text: 'Start exercise',
                textColor: Color(0xFFFFC400),
                onTap: onExerciseTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopupButton extends StatelessWidget {
  final String text;
  final Color textColor;
  final VoidCallback onTap;

  const _PopupButton({
    required this.text,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyLessonsState extends StatelessWidget {
  const _EmptyLessonsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Image(
              image: AssetImage('assets/images/Oyu_uyktauda.png'),
              width: 150,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 20),
            Text(
              'Әзірге урок жоқ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5B21B6),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Админ урок қосқаннан кейін осында шығады',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8A8A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;

  const _HeaderStat({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
        title: Text(title.isEmpty ? 'Theory Lesson $lessonNumber' : title),
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
                    'Level: $level',
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
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    lectureText.trim().isNotEmpty
                        ? lectureText
                        : 'Бұл сабаққа теория әлі қосылмаған',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.5,
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
  static const Color green = Color(0xFF58CC02);
  static const Color greenDark = Color(0xFF46A800);
  static const Color red = Color(0xFFFF4B4B);
  static const Color blue = Color(0xFF1899D6);
  static const Color bg = Color(0xFFF7F7F7);
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFE2E2E2);
  static const Color textPrimary = Color(0xFF2B2238);
  static const Color textSecondary = Color(0xFF7D7D7D);

  final LessonService _lessonService = LessonService();

  bool _loading = true;
  String? _error;

  List<TaskModel> _tasks = <TaskModel>[];
  int _currentTaskIndex = 0;
  List<String> _slots = <String>[];
  List<String> _bank = <String>[];
  _ExerciseStage _stage = _ExerciseStage.building;
  int _lives = 3;
  int _earnedXp = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tasks = await _lessonService.getLessonTasks(widget.lessonId);
      if (!mounted) return;

      setState(() {
        _tasks = tasks.where((t) => t.correctWords.isNotEmpty).toList();
        _currentTaskIndex = 0;
        _earnedXp = 0;
        _lives = 3;
        _loading = false;
        if (_tasks.isNotEmpty) {
          _setupTask(_tasks.first);
        } else {
          _slots = <String>[];
          _bank = <String>[];
          _stage = _ExerciseStage.building;
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

  void _setupTask(TaskModel task) {
    final correctWords = _cleanWords(task.correctWords);
    final options = _cleanWords(
      task.optionsWords.isNotEmpty ? task.optionsWords : task.correctWords,
    );

    _slots = <String>[];
    _bank = options.isNotEmpty ? [...options] : [...correctWords];
    _stage = _ExerciseStage.building;
  }

  List<String> _cleanWords(List<String> words) {
    return words
        .expand((item) => item
        .replaceAll(',', ' ')
        .split(RegExp(r'\s+')))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool get _canCheck {
    if (_tasks.isEmpty || _stage != _ExerciseStage.building) return false;
    return _slots.isNotEmpty; // 🔥 кем болса да тексеруге болады
  }

  double get _progress {
    if (_tasks.isEmpty) return 0;
    return _currentTaskIndex / _tasks.length;
  }

  void _placeWord(int bankIndex) {
    if (_stage != _ExerciseStage.building) return;
    if (bankIndex < 0 || bankIndex >= _bank.length) return;

    setState(() {
      final word = _bank.removeAt(bankIndex);
      _slots.add(word);
    });
  }

  void _removeWord(int slotIndex) {
    if (_stage != _ExerciseStage.building) return;
    if (slotIndex < 0 || slotIndex >= _slots.length) return;

    setState(() {
      final word = _slots.removeAt(slotIndex);
      _bank.add(word);
    });
  }

  bool _isCorrectAnswer() {
    final correct = _cleanWords(_currentTask.correctWords);
    if (_slots.length != correct.length) return false;

    for (int i = 0; i < correct.length; i++) {
      if (_slots[i].trim() != correct[i].trim()) return false;
    }
    return true;
  }

  Future<void> _handleCheck() async {
    if (_stage == _ExerciseStage.correct || _stage == _ExerciseStage.wrong) {
      _goNext();
      return;
    }

    if (!_canCheck) return;

    debugPrint('CURRENT TASK ID: ${_currentTask.id}');
    debugPrint('ANSWER: $_slots');

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

    if (_lives > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() {
        _slots = <String>[];
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
      return;
    }

    setState(() {
      _stage = _ExerciseStage.finished;
    });
  }

  void _restartAll() {
    setState(() {
      _currentTaskIndex = 0;
      _lives = 3;
      _earnedXp = 0;
      if (_tasks.isNotEmpty) _setupTask(_tasks.first);
    });
  }

  String _buttonText() {
    if (_stage == _ExerciseStage.correct) {
      return _currentTaskIndex < _tasks.length - 1 ? 'Продолжить' : 'Завершить';
    }
    if (_stage == _ExerciseStage.wrong && _lives == 0) return 'Продолжить';
    return 'Проверить';
  }

  Color _buttonColor() {
    if (_stage == _ExerciseStage.wrong && _lives == 0) return red;
    if (_stage == _ExerciseStage.correct || _canCheck) return green;
    return const Color(0xFFE8E8E8);
  }

  Color _buttonTextColor() {
    if (_stage == _ExerciseStage.correct || _canCheck || _stage == _ExerciseStage.wrong) {
      return Colors.white;
    }
    return textSecondary;
  }

  VoidCallback? _buttonAction() {
    if (_stage == _ExerciseStage.correct) return _handleCheck;
    if (_stage == _ExerciseStage.wrong && _lives == 0) return _handleCheck;
    if (_canCheck) return _handleCheck;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: green)),
        ),
      );
    }

    if (_error != null) {
      return _ExerciseMessageScaffold(
        lives: _lives,
        progress: 0,
        onClose: () => Navigator.pop(context),
        icon: Icons.cloud_off_rounded,
        title: 'Тапсырмалар жүктелмеді',
        message: _error!,
        buttonText: 'Қайта жүктеу',
        onButtonTap: _loadTasks,
      );
    }

    if (_tasks.isEmpty) {
      return _ExerciseMessageScaffold(
        lives: _lives,
        progress: 0,
        onClose: () => Navigator.pop(context),
        icon: Icons.assignment_outlined,
        title: 'Exercise жоқ',
        message: 'Бұл сабаққа әзірге exercise қосылмаған',
        buttonText: 'Жабу',
        onButtonTap: () => Navigator.pop(context),
      );
    }

    if (_stage == _ExerciseStage.finished) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: _FinishedExerciseView(
            total: _tasks.length,
            xp: _earnedXp,
            onRestart: _restartAll,
            onClose: () => Navigator.pop(context),
          ),
        ),
      );
    }

    final correctWords = _cleanWords(_currentTask.correctWords);
    final prompt = _currentTask.promptText.trim().isNotEmpty
        ? _currentTask.promptText.trim()
        : 'Сөздерді дұрыс ретпен орналастыр';
    final bool isCorrect = _stage == _ExerciseStage.correct;
    final bool isWrong = _stage == _ExerciseStage.wrong;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _HtmlLikeExerciseHeader(
              lives: _lives,
              progress: _progress,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                children: [
                  const Text(
                    'TRANSLATE THIS SENTENCE',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PromptBox(text: prompt),
                  const SizedBox(height: 28),
                  _AnswerArea(
                    words: _slots,
                    stage: _stage,
                    correctWords: correctWords,
                    onTapWord: _removeWord,
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1.5, thickness: 1.5, color: border),
                  const SizedBox(height: 24),
                  _WordBank(words: _bank, onTapWord: _placeWord),
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/Oyu.png',
                        height: 80,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Put the words in correct order',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isCorrect)
                    const _FeedbackBox(
                      isCorrect: true,
                      title: 'Дұрыс жауап!',
                      subtitle: 'Отличная работа!',
                    ),
                  if (isWrong)
                    _FeedbackBox(
                      isCorrect: false,
                      title: 'Жауап қате',
                      subtitle: _lives == 0
                          ? 'Правильно: ${correctWords.join(' ')}'
                          : 'Попробуй ещё раз',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _buttonAction(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canCheck
                        ? const Color(0xFF58CC02)
                        : const Color(0xFFE5E5E5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _stage == _ExerciseStage.correct
                        ? 'CONTINUE'
                        : _stage == _ExerciseStage.wrong && _lives == 0
                        ? 'CONTINUE'
                        : 'CHECK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _canCheck || _stage != _ExerciseStage.building
                          ? Colors.white
                          : Colors.grey,
                    ),
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


class _HtmlLikeExerciseHeader extends StatelessWidget {
  final int lives;
  final double progress;
  final VoidCallback onClose;

  const _HtmlLikeExerciseHeader({
    required this.lives,
    required this.progress,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Row(
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Text(
                  i < lives ? '♥' : '♡',
                  style: const TextStyle(
                    color: Color(0xFFFF4B4B),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 16,
                backgroundColor: const Color(0xFFE8E8E8),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF58CC02)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Color(0xFF7D7D7D)),
          ),
        ],
      ),
    );
  }
}

class _PromptBox extends StatelessWidget {
  final String text;

  const _PromptBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AnswerArea extends StatelessWidget {
  final List<String> words;
  final List<String> correctWords;
  final _ExerciseStage stage;
  final void Function(int index) onTapWord;

  const _AnswerArea({
    required this.words,
    required this.correctWords,
    required this.stage,
    required this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: words.isEmpty
          ? const Text(
        'Tap words below',
        style: TextStyle(color: Colors.grey),
      )
          : Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(words.length, (i) {
          return GestureDetector(
            onTap: () => onTapWord(i),
            child: Chip(
              label: Text(words[i]),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.grey),
              ),
            ),
          );
        }),
      ),
    );
  }
}
class _WordBank extends StatelessWidget {
  final List<String> words;
  final void Function(int index) onTapWord;

  const _WordBank({
    required this.words,
    required this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(words.length, (i) {
        final word = words[i];

        return GestureDetector(
          onTap: () => onTapWord(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6A00FF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              word,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _ExerciseChip({
    required this.text,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  final bool isCorrect;
  final String title;
  final String subtitle;

  const _FeedbackBox({
    required this.isCorrect,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF58CC02) : const Color(0xFFFF4B4B);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFF0FFF0) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isCorrect ? '🎉' : '😅', style: const TextStyle(fontSize: 24)),
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
                    color: Color(0xFF2B2238),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF7D7D7D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseMessageScaffold extends StatelessWidget {
  final int lives;
  final double progress;
  final VoidCallback onClose;
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonTap;

  const _ExerciseMessageScaffold({
    required this.lives,
    required this.progress,
    required this.onClose,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _HtmlLikeExerciseHeader(lives: lives, progress: progress, onClose: onClose),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 64, color: const Color(0xFF7D7D7D)),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6A00FF),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF7D7D7D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: onButtonTap, child: Text(buttonText)),
                    ],
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

class _FinishedExerciseView extends StatelessWidget {
  final int total;
  final int xp;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _FinishedExerciseView({
    required this.total,
    required this.xp,
    required this.onRestart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Color(0xFF7D7D7D)),
            ),
          ),
          const Spacer(),
          const Text('🏆', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'Урок завершён!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2238),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Жарайсың! $total тапсырма аяқталды. XP: $xp',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Color(0xFF7D7D7D)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Ещё раз',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ExerciseTopBar extends StatelessWidget {
  final int lives;
  final VoidCallback onClose;

  const _ExerciseTopBar({
    required this.lives,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF6A00FF),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.yellow, size: 24),
              const SizedBox(width: 6),
              Text(
                '$lives',
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
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}

class _ExerciseProgressCard extends StatelessWidget {
  final String lessonTitle;
  final String lessonLevel;
  final int current;
  final int total;
  final int xp;

  const _ExerciseProgressCard({
    required this.lessonTitle,
    required this.lessonLevel,
    required this.current,
    required this.total,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lessonTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF3E1D73),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Level: $lessonLevel',
                  style: const TextStyle(
                    color: Color(0xFF7D6B99),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'XP: $xp',
                style: const TextStyle(
                  color: Color(0xFF35C96C),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE9DFFF),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6A00FF)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$current / $total тапсырма',
            style: const TextStyle(
              color: Color(0xFF6D5C8B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isCorrectMode;

  const _WordChip({
    required this.text,
    required this.onTap,
    required this.isCorrectMode,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1.5,
      shadowColor: const Color(0xFF6A00FF).withOpacity(0.12),
      child: InkWell(
        onTap: isCorrectMode ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCorrectMode
                  ? Colors.grey.shade300
                  : const Color(0xFF35C96C),
              width: 2,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isCorrectMode ? Colors.grey : const Color(0xFF35C96C),
            ),
          ),
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
            final word = words[i];
            final isFilled = word != null;
            final isCorrectChip =
                showCorrectStyle && isFilled && word == correctWords[i];

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              elevation: isFilled ? 1.5 : 0,
              shadowColor: const Color(0xFF6A00FF).withOpacity(0.14),
              child: InkWell(
                onTap: isFilled && !showCorrectStyle ? () => onTapSlot(i) : null,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 86, minHeight: 58),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCorrectChip
                          ? const Color(0xFF35C96C)
                          : const Color(0xFFD5C7F0),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    word ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isCorrectChip
                          ? const Color(0xFF35C96C)
                          : const Color(0xFF2B2238),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Container(height: 2, color: Colors.black26),
        const SizedBox(height: 16),
        Container(height: 2, color: Colors.black26),
        const SizedBox(height: 16),
        Container(height: 2, color: Colors.black26),
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
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFF2B2238),
          ),
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
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          color: Color(0xFF2B2238),
          height: 1.35,
        ),
      ),
    );
  }
}