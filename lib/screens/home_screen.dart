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
import 'package:kazakh_learning_app/screens/exercise_word_order_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color purple = Color(0xFF5D0099);

  int currentIndex = 0;
  final _auth = AuthService();
  String _name = 'User';
  int _homePageEpoch = 0;
  int _profilePageEpoch = 0;
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
      HomePage(
        key: ValueKey('home-page-$_homePageEpoch'),
        userName: _name,
      ),
      const AlphabetScreen(),
      const AskAiScreen(),
      const GameZoneScreen(),
      ProfileScreen(
        key: ValueKey('profile-page-$_profilePageEpoch'),
        userName: _name,
      ),
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
    setState(() {
      currentIndex = index;

      if (index == 0) {
        _homePageEpoch++;
        pages[0] = HomePage(
          key: ValueKey('home-page-$_homePageEpoch'),
          userName: _name,
        );
      }

      if (index == 4) {
        _profilePageEpoch++;
        pages[4] = ProfileScreen(
          key: ValueKey('profile-page-$_profilePageEpoch'),
          userName: _name,
        );
      }
    });

    await _loadNameFromCache();

    if (index == 0 || index == 4) {
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
  static const Color purple = Color(0xFF5D0099);
  static const Color darkPurple = Color(0xFF3D0067);

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
          onExerciseTap: () async {
            Navigator.pop(context);

            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciseTaskSelectScreen(
                  lessonId: lesson.id,
                  lessonNumber: lessonNumber,
                  lessonTitle: lesson.title,
                  level: lesson.level,
                ),
              ),
            );

            if (!mounted) return;

            if (updated == true) {
              setState(() {
                _futureLessons = _lessonService.getUserLessons();
              });
            }
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
                        final groupCount = (lessons.length / 6).ceil();

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                          itemCount: groupCount,
                          itemBuilder: (context, groupIndex) {
                            final start = groupIndex * 6;
                            final end = math.min(start + 6, lessons.length);
                            final groupLessons = lessons.sublist(start, end);

                            return _LessonCircleGroup(
                              base: base,
                              lessons: groupLessons,
                              startNumber: start + 1,
                              showBox: groupLessons.length == 6,
                              mascotAsset: groupIndex.isOdd
                                  ? 'assets/images/Oyu_uyktauda.png'
                                  : 'assets/images/Oyu.png',
                              onTapLesson: (lesson, number) {
                                _openLessonSheet(lesson, number);
                              },
                            );
                          },
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
        bottom: 14,
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
          FutureBuilder<Map<String, dynamic>>(
            future: AuthService().me(),
            builder: (context, snapshot) {
              final rawXp = snapshot.data?['xp'] ?? 0;
              final xp = rawXp is int ? rawXp : int.tryParse('$rawXp') ?? 0;

              return _HeaderStat(
                icon: Icons.stars_rounded,
                iconColor: Colors.orange,
                value: '$xp XP',
              );
            },
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 15,
            ),
            label: const Text(
              'Выйти',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
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
  final int startNumber;
  final bool showBox;
  final String mascotAsset;
  final void Function(LessonModel lesson, int number) onTapLesson;

  const _LessonCircleGroup({
    required this.base,
    required this.lessons,
    required this.startNumber,
    required this.showBox,
    required this.mascotAsset,
    required this.onTapLesson,
  });

  @override
  Widget build(BuildContext context) {
    final double size = base * 0.95;
    final double eggSize = base * 0.15;
    final double oyuSize = base * 0.34;
    final double blockHeight = showBox ? size + eggSize * 0.9 : size;

    return SizedBox(
      height: blockHeight,
      child: Center(
        child: SizedBox(
          width: size,
          height: blockHeight,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        mascotAsset,
                        width: oyuSize,
                        fit: BoxFit.contain,
                      ),
                      for (int i = 0; i < lessons.length && i < 6; i++)
                        _buildEggPosition(
                          lesson: lessons[i],
                          index: i,
                          size: eggSize,
                          number: startNumber + i,
                          onTap: () => onTapLesson(
                            lessons[i],
                            startNumber + i,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (showBox)
                Positioned(
                  top: size - eggSize * 0.2,
                  child: Image.asset(
                    'assets/images/Qorap.png',
                    width: eggSize,
                    height: eggSize,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEggPosition({
    required LessonModel lesson,
    required int index,
    required double size,
    required int number,
    required VoidCallback onTap,
  }) {
    const positions = [
      Offset(0, -1.95),
      Offset(-1.55, -0.75),
      Offset(1.55, -0.75),
      Offset(-1.55, 0.95),
      Offset(1.55, 0.95),
      Offset(0, 2.0),
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
                    Text(
                      '$number',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
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

  static const Color purple = Color(0xFF5D0099);
  static const Color darkPurple = Color(0xFF3D0067);

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
    const purple = Color(0xFF5D0099);

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
