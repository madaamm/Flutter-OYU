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
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 32,
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
      Offset(0, 2.0),
      Offset(0, -1.95),
      Offset(-1.55, -0.75),
      Offset(1.55, -0.75),
      Offset(-1.55, 0.95),
      Offset(1.55, 0.95),
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

enum _ExerciseStage { building, checkedCorrect, finished }

class _ExerciseWordOrderScreenState extends State<ExerciseWordOrderScreen> {
  static const Color purple = Color(0xFF6A00FF);
  static const Color green = Color(0xFF35C96C);

  static const String kOyuHappy = 'assets/images/Oyu.png';
  static const String kOyuSleep = 'assets/images/Oyu_uyktauda.png';

  final LessonService _lessonService = LessonService();

  bool _loading = true;
  String? _error;

  List<TaskModel> _tasks = <TaskModel>[];
  int _currentTaskIndex = 0;
  List<String?> _slots = <String?>[];
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
        _tasks = tasks;
        _currentTaskIndex = 0;
        _earnedXp = 0;
        _stage = _ExerciseStage.building;
        if (_tasks.isNotEmpty) {
          _setupTask(_tasks.first);
        } else {
          _slots = [];
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _setupTask(TaskModel task) {
    final correctWords = task.correctWords
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    _slots = List<String?>.filled(correctWords.length, null);
    _stage = _ExerciseStage.building;
  }

  TaskModel get _currentTask => _tasks[_currentTaskIndex];

  bool get _allFilled => _slots.isNotEmpty && _slots.every((e) => e != null);

  bool _isPlaced(String word) => _slots.contains(word);

  List<String> get _availableWords {
    final source = _currentTask.optionsWords.isNotEmpty
        ? _currentTask.optionsWords
        : [..._currentTask.correctWords];

    return source
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((word) => !_isPlaced(word))
        .toList();
  }

  void _placeWord(String word) {
    if (_stage != _ExerciseStage.building) return;

    final index = _slots.indexWhere((e) => e == null);
    if (index == -1) return;

    setState(() {
      _slots[index] = word;
    });
  }

  void _removeFromSlot(int index) {
    if (_stage != _ExerciseStage.building) return;
    if (index < 0 || index >= _slots.length) return;

    setState(() {
      _slots[index] = null;
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i].trim() != b[i].trim()) return false;
    }

    return true;
  }

  void _checkAnswer() {
    if (!_allFilled) return;

    final answer = _slots.cast<String>();
    final correct = _listEquals(answer, _currentTask.correctWords);

    if (correct) {
      setState(() {
        _earnedXp += _currentTask.xpReward;
        _stage = _ExerciseStage.checkedCorrect;
      });
      return;
    }

    final nextLives = (_lives - 1).clamp(0, 3);

    setState(() {
      _lives = nextLives;
      _slots = List<String?>.filled(_currentTask.correctWords.length, null);
    });

    if (_lives == 0) {
      _showOutOfLivesDialog();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Қате жауап. Қайта көріңіз.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

    _showFinishDialog();
  }

  Future<void> _showOutOfLivesDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Жүрек бітті',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Қайталап көріңіз.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Жабу'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _lives = 3;
                  _currentTaskIndex = 0;
                  _earnedXp = 0;
                  if (_tasks.isNotEmpty) {
                    _setupTask(_tasks.first);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Қайта бастау'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFinishDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Керемет!',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Сіз ${_tasks.length} тапсырманы аяқтадыңыз.\nЖиналған XP: $_earnedXp',
            style: const TextStyle(fontWeight: FontWeight.w500, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Жалғастыру'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: purple,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: purple,
        body: SafeArea(
          child: Column(
            children: [
              _ExerciseTopBar(
                lives: _lives,
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(34),
                      topRight: Radius.circular(34),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Тапсырмалар жүктелмеді',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: purple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadTasks,
                            child: const Text('Қайта жүктеу'),
                          ),
                        ],
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

    if (_tasks.isEmpty) {
      return Scaffold(
        backgroundColor: purple,
        body: SafeArea(
          child: Column(
            children: [
              _ExerciseTopBar(
                lives: _lives,
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(34),
                      topRight: Radius.circular(34),
                    ),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Бұл сабаққа әзірге exercise қосылмаған',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5B21B6),
                        ),
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

    if (_slots.isEmpty) {
      return Scaffold(
        backgroundColor: purple,
        body: SafeArea(
          child: Column(
            children: [
              _ExerciseTopBar(
                lives: _lives,
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(34),
                      topRight: Radius.circular(34),
                    ),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Жарамды тапсырмалар табылмады',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5B21B6),
                        ),
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

    final task = _currentTask;
    final isCorrect = _stage == _ExerciseStage.checkedCorrect;

    return Scaffold(
      backgroundColor: purple,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ExerciseTopBar(
              lives: _lives,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(34),
                    topRight: Radius.circular(34),
                  ),
                ),
                child: Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      children: [
                        _ExerciseProgressCard(
                          lessonTitle: widget.lessonTitle,
                          lessonLevel: widget.level,
                          current: _currentTaskIndex + 1,
                          total: _tasks.length,
                          xp: _earnedXp,
                        ),
                        const SizedBox(height: 18),
                        _SpeechTop(text: task.promptText),
                        const SizedBox(height: 22),
                        _AnswerLine(
                          words: _slots,
                          correctWords: task.correctWords,
                          showCorrectStyle: isCorrect,
                          onTapSlot: _removeFromSlot,
                        ),
                        const SizedBox(height: 26),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          alignment: WrapAlignment.center,
                          children: _availableWords
                              .map(
                                (word) => _WordChip(
                              text: word,
                              isCorrectMode: isCorrect,
                              onTap: () => _placeWord(word),
                            ),
                          )
                              .toList(),
                        ),
                        const SizedBox(height: 34),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Image.asset(
                              isCorrect ? kOyuHappy : kOyuSleep,
                              width: 96,
                              height: 96,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SpeechBottom(
                                text: isCorrect
                                    ? 'Тамаша! Келесі тапсырмаға өт.'
                                    : 'Сөздерді дұрыс ретпен орналастыр.',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: SizedBox(
                        height: 58,
                        child: ElevatedButton(
                          onPressed: isCorrect
                              ? _goNext
                              : (_allFilled ? _checkAnswer : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            disabledBackgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            isCorrect ? 'Continue' : 'Check',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
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