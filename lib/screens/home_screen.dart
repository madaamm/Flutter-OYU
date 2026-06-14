import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/lesson_model.dart';
import 'package:kazakh_learning_app/screens/alphabet_screen.dart';
import 'package:kazakh_learning_app/screens/ask_ai_screen.dart';
import 'package:kazakh_learning_app/screens/auth_screen.dart';
import 'package:kazakh_learning_app/screens/game_zone_screen.dart';
import 'package:kazakh_learning_app/screens/profile_page.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/services/lesson_service.dart';
import 'package:kazakh_learning_app/screens/exercise_word_order_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  static const int _levelDividerRewardAmount = 10;

  final _lessonService = LessonService();
  late Future<List<LessonModel>> _futureLessons;
  String _userLevel = 'A0';
  Set<String> _claimedCircleRewardKeys = <String>{};
  Set<String> _claimedLevelRewardKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _futureLessons = _lessonService.getUserLessons();
    _loadUserLevel();
    _loadCircleRewardClaims();
    _loadLevelRewardClaims();
  }


  Future<void> _loadUserLevel() async {
    try {
      final me = await AuthService().me();
      final level = (me['level'] ?? 'A0').toString().trim().toUpperCase();

      if (!mounted) return;

      setState(() {
        _userLevel = level.isEmpty ? 'A0' : level;
      });
    } catch (_) {}
  }
  Future<void> _refreshLessons() async {
    setState(() {
      _futureLessons = _lessonService.getUserLessons();
    });
    await _futureLessons;
    await _loadUserLevel();
    await _loadCircleRewardClaims();
    await _loadLevelRewardClaims();
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
    );
  }


  static const Map<String, int> _levelOrder = {
    'A0': 0,
    'A1': 1,
    'A2': 2,
    'B1': 3,
    'B2': 4,
    'C1': 5,
    'C2': 6,
  };

  int _levelRank(String level) {
    return _levelOrder[level.trim().toUpperCase()] ?? 0;
  }

  bool _isLessonCompleted(LessonModel lesson) {
    return lesson.progressStatus == 'COMPLETED';
  }

  bool _isGroupCompleted(_LessonGroupData group) {
    return group.lessons.isNotEmpty && group.lessons.every(_isLessonCompleted);
  }

  String _circleRewardKey(_LessonGroupData group) {
    return '${group.level}:${group.indexWithinLevel}';
  }

  bool _isCircleRewardClaimed(_LessonGroupData group) {
    return _claimedCircleRewardKeys.contains(_circleRewardKey(group));
  }

  String _levelRewardKey(String level) {
    return level.trim().toUpperCase();
  }

  bool _isLevelRewardClaimed(String level) {
    return _claimedLevelRewardKeys.contains(_levelRewardKey(level));
  }

  bool _isLevelCompleted(String level, List<_LessonGroupData> allGroups) {
    final normalizedLevel = _levelRewardKey(level);
    final levelGroups = allGroups.where(
      (group) => _levelRewardKey(group.level) == normalizedLevel,
    );
    return levelGroups.isNotEmpty && levelGroups.every(_isGroupCompleted);
  }

  Future<void> _loadCircleRewardClaims() async {
    try {
      final claims = await _lessonService.getCircleRewardClaims();
      if (!mounted) return;

      setState(() {
        _claimedCircleRewardKeys = claims.map((claim) {
          final level = (claim['level'] ?? '').toString().trim().toUpperCase();
          final groupIndexRaw = claim['groupIndex'];
          final groupIndex = groupIndexRaw is int
              ? groupIndexRaw
              : int.tryParse('$groupIndexRaw') ?? 0;
          return '$level:$groupIndex';
        }).toSet();
      });
    } catch (_) {}
  }

  Future<void> _loadLevelRewardClaims() async {
    try {
      final claims = await _lessonService.getLevelRewardClaims();
      if (!mounted) return;

      setState(() {
        _claimedLevelRewardKeys = claims
            .map((claim) => (claim['level'] ?? '').toString().trim().toUpperCase())
            .where((item) => item.isNotEmpty)
            .toSet();
      });
    } catch (_) {}
  }

  Future<void> _claimLevelReward(
    String level,
    List<_LessonGroupData> allGroups,
  ) async {
    final normalizedLevel = _levelRewardKey(level);

    if (_isLevelRewardClaimed(normalizedLevel)) {
      if (!mounted) return;
      await _showSilverEggNotice(
        title: 'Reward collected',
        message: 'You have already collected the reward for $normalizedLevel.',
      );
      return;
    }

    if (!_isLevelCompleted(normalizedLevel, allGroups)) {
      if (!mounted) return;
      await _showSilverEggNotice(
        title: '$normalizedLevel is not complete',
        message: 'Finish all lessons in $normalizedLevel to unlock this reward.',
      );
      return;
    }

    try {
      final result = await _lessonService.claimLevelReward(
        level: normalizedLevel,
      );

      if (!mounted) return;

      final alreadyClaimed = result['alreadyClaimed'] == true;
      final earnedRaw = result['earnedSilvEgg'];
      final earned = earnedRaw is int ? earnedRaw : int.tryParse('$earnedRaw') ?? 0;

      if (!alreadyClaimed) {
        setState(() {
          _claimedLevelRewardKeys = <String>{
            ..._claimedLevelRewardKeys,
            normalizedLevel,
          };
        });

        await _showRewardDialog(
          amount: earned > 0 ? earned : _levelDividerRewardAmount,
          title: 'Level Reward Unlocked',
          subtitle: '$normalizedLevel is complete',
        );
        return;
      }

      await _showSilverEggNotice(
        title: 'Reward collected',
        message: 'You have already collected the reward for $normalizedLevel.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reward error: $e')),
      );
    }
  }

  Future<void> _claimCircleReward(_LessonGroupData group) async {
    if (group.lessons.length != 6) return;

    if (_isCircleRewardClaimed(group)) {
      if (!mounted) return;
      await _showSilverEggNotice(
        title: 'Reward collected',
        message: 'You have already collected the Silver Egg for this circle.',
      );
      return;
    }

    if (!_isGroupCompleted(group)) {
      if (!mounted) return;
      await _showSilverEggNotice(
        title: 'Silver Egg is locked',
        message: 'Complete all 6 lessons in this circle to unlock this reward.',
      );
      return;
    }

    try {
      final result = await _lessonService.claimCircleReward(
        level: group.level,
        groupIndex: group.indexWithinLevel,
      );

      if (!mounted) return;

      final alreadyClaimed = result['alreadyClaimed'] == true;
      final earnedRaw = result['earnedSilvEgg'];
      final earned = earnedRaw is int ? earnedRaw : int.tryParse('$earnedRaw') ?? 0;

      if (!alreadyClaimed) {
        setState(() {
          _claimedCircleRewardKeys = <String>{
            ..._claimedCircleRewardKeys,
            _circleRewardKey(group),
          };
        });

        await _showRewardDialog(
          amount: earned,
          title: 'Bonus Collected',
          subtitle: 'Oyu prepared a reward for you',
          rewardAsset: 'assets/images/Qorap.png',
        );
        return;
      }

      await _showSilverEggNotice(
        title: 'Reward collected',
        message: 'You have already collected the Silver Egg for this circle.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reward error: $e')),
      );
    }
  }

  Future<void> _showSilverEggNotice({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (_) => _SilverEggNoticeDialog(
        title: title,
        message: message,
      ),
    );
  }

  Future<void> _showRewardDialog({
    required int amount,
    required String title,
    required String subtitle,
    String rewardAsset = 'assets/images/Qorap.png',
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (_) => _RewardSuccessDialog(
        title: title,
        message: subtitle,
        amount: amount,
        rewardAsset: rewardAsset,
      ),
    );
  }

  List<_LessonGroupData> _buildLessonGroups(List<LessonModel> lessons) {
    final groupedByLevel = <String, List<LessonModel>>{};

    for (final lesson in lessons) {
      groupedByLevel.putIfAbsent(lesson.level, () => <LessonModel>[]).add(lesson);
    }

    final orderedLevels = groupedByLevel.keys.toList()
      ..sort((a, b) => _levelRank(a).compareTo(_levelRank(b)));

    final groups = <_LessonGroupData>[];
    var startNumber = 1;

    for (final level in orderedLevels) {
      final levelLessons = groupedByLevel[level]!
        ..sort((a, b) {
          final orderCompare = a.orderIndex.compareTo(b.orderIndex);
          if (orderCompare != 0) return orderCompare;
          return a.id.compareTo(b.id);
        });

      for (var i = 0; i < levelLessons.length; i += 6) {
        final slice = levelLessons.sublist(
          i,
          math.min(i + 6, levelLessons.length),
        );

        groups.add(
          _LessonGroupData(
            level: level,
            lessons: slice,
            startNumber: startNumber,
            indexWithinLevel: i ~/ 6,
          ),
        );

        startNumber += slice.length;
      }
    }

    return groups;
  }

  bool _isGroupUnlocked(
    _LessonGroupData group,
    List<_LessonGroupData> allGroups,
  ) {
    final userRank = _levelRank(_userLevel);
    final groupRank = _levelRank(group.level);

    if (groupRank < userRank) {
      return true;
    }

    if (groupRank > userRank) {
      return false;
    }

    if (group.indexWithinLevel == 0) {
      return true;
    }

    final previousGroups = allGroups.where(
      (item) =>
          item.level == group.level && item.indexWithinLevel < group.indexWithinLevel,
    );

    return previousGroups.every(_isGroupCompleted);
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
                                      'Lessons failed to load',
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

                    return LayoutBuilder(
                      builder: (context, c) {
                        final base = math.min(c.maxWidth, c.maxHeight);
                        final groups = _buildLessonGroups(lessons);

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                          itemCount: groups.length,
                          itemBuilder: (context, groupIndex) {
                            final group = groups[groupIndex];
                            final isUnlockedGroup = _isGroupUnlocked(group, groups);

                            final showLevelDivider =
                                groupIndex > 0 && groups[groupIndex - 1].level != group.level;

                            return Column(
                              children: [
                                if (showLevelDivider)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: _LevelDivider(
                                      levelLabel: groups[groupIndex - 1].level,
                                      isCompleted: _isLevelCompleted(
                                        groups[groupIndex - 1].level,
                                        groups,
                                      ),
                                      isClaimed: _isLevelRewardClaimed(
                                        groups[groupIndex - 1].level,
                                      ),
                                      onTap: () => _claimLevelReward(
                                        groups[groupIndex - 1].level,
                                        groups,
                                      ),
                                    ),
                                  ),
                                _LessonCircleGroup(
                                  base: base,
                                  lessons: group.lessons,
                                  startNumber: group.startNumber,
                                  showBox: group.lessons.length == 6,
                                  mascotAsset: isUnlockedGroup
                                      ? 'assets/images/Oyu.png'
                                      : 'assets/images/Oyu_uyktauda.png',
                                  isLockedGroup: !isUnlockedGroup,
                                  isRewardClaimed: _isCircleRewardClaimed(group),
                                  onTapReward: group.lessons.length == 6
                                      ? () => _claimCircleReward(group)
                                      : null,
                                  onTapLesson: (lesson, number) {
                                    _openLessonSheet(lesson, number);
                                  },
                                ),
                              ],
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
              'Logout',
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

class _LessonGroupData {
  final String level;
  final List<LessonModel> lessons;
  final int startNumber;
  final int indexWithinLevel;

  const _LessonGroupData({
    required this.level,
    required this.lessons,
    required this.startNumber,
    required this.indexWithinLevel,
  });
}
class _LevelDivider extends StatelessWidget {
  final String levelLabel;
  final bool isCompleted;
  final bool isClaimed;
  final VoidCallback onTap;

  const _LevelDivider({
    required this.levelLabel,
    required this.isCompleted,
    required this.isClaimed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double opacity = isClaimed ? 0.58 : (isCompleted ? 1.0 : 0.75);

    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: Color(0xFFD9C2FF),
            thickness: 4,
            endIndent: 16,
          ),
        ),
        Opacity(
          opacity: opacity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(40),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Tooltip(
                  message: isClaimed
                      ? '$levelLabel reward already claimed'
                      : isCompleted
                          ? 'Claim $levelLabel reward: +10'
                          : 'Complete all $levelLabel lessons first',
                  child: Image.asset(
                    'assets/images/Qorap.png',
                    width: 58,
                    height: 58,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Color(0xFFD9C2FF),
            thickness: 4,
            indent: 16,
          ),
        ),
      ],
    );
  }
}
class _LessonCircleGroup extends StatelessWidget {
  final double base;
  final List<LessonModel> lessons;
  final int startNumber;
  final bool showBox;
  final String mascotAsset;
  final bool isLockedGroup;
  final bool isRewardClaimed;
  final VoidCallback? onTapReward;
  final void Function(LessonModel lesson, int number) onTapLesson;

  const _LessonCircleGroup({
    required this.base,
    required this.lessons,
    required this.startNumber,
    required this.showBox,
    required this.mascotAsset,
    required this.isLockedGroup,
    required this.isRewardClaimed,
    required this.onTapReward,
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
                          context: context,
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
                  child: Opacity(
                    opacity: isRewardClaimed ? 0.58 : 1,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTapReward,
                        borderRadius: BorderRadius.circular(eggSize),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Image.asset(
                            'assets/images/Qorap.png',
                            width: eggSize,
                            height: eggSize,
                            fit: BoxFit.contain,
                          ),
                        ),
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

  Widget _buildEggPosition({
    required BuildContext context,
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
              onTap: isLockedGroup
                  ? () => showDialog<void>(
                        context: context,
                        barrierColor: Colors.black.withOpacity(0.28),
                        builder: (_) => const _LockedLessonDialog(),
                      )
                  : onTap,
              borderRadius: BorderRadius.circular(size),
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      isLockedGroup
                          ? 'assets/images/SilverEgg.png'
                          : lesson.progressStatus == 'COMPLETED'
                              ? 'assets/images/GoldEgg.png'
                              : lesson.progressStatus == 'IN_PROGRESS'
                                  ? 'assets/images/FioGoldEgg.png'
                                  : 'assets/images/Pink_egg.png',
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

class _LockedLessonDialog extends StatelessWidget {
  const _LockedLessonDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Image(
                image: AssetImage('assets/images/crybaby.png'),
                width: 112,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 12),
              Expanded(
                child: _LockedSpeechBubble(
                  title: 'Locked lesson',
                  message: 'Complete the previous levels to unlock this lesson.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6A00FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SilverEggNoticeDialog extends StatelessWidget {
  final String title;
  final String message;

  const _SilverEggNoticeDialog({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Image(
                image: AssetImage('assets/images/angrybaby.png'),
                width: 112,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LockedSpeechBubble(
                  title: title,
                  message: message,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6A00FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final int amount;
  final String rewardAsset;

  const _RewardSuccessDialog({
    required this.title,
    required this.message,
    required this.amount,
    required this.rewardAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Image(
                image: AssetImage('assets/images/happybaby.png'),
                width: 112,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RewardSpeechBubble(
                  title: title,
                  message: message,
                  amount: amount,
                  rewardAsset: rewardAsset,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6A00FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardSpeechBubble extends StatelessWidget {
  final String title;
  final String message;
  final int amount;
  final String rewardAsset;

  const _RewardSpeechBubble({
    required this.title,
    required this.message,
    required this.amount,
    required this.rewardAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F1FF),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A00FF).withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF41107A),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF5D4A77),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      rewardAsset,
                      width: 42,
                      height: 42,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+$amount',
                      style: const TextStyle(
                        color: Color(0xFF41107A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: -12,
          bottom: 24,
          child: Transform.rotate(
            angle: 0.78,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F1FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedSpeechBubble extends StatelessWidget {
  final String title;
  final String message;
  const _LockedSpeechBubble({
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F1FF),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A00FF).withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF41107A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF5D4A77),
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: -12,
          bottom: 18,
          child: Transform.rotate(
            angle: 0.78,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F1FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
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
              'No lessons yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5B21B6),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Lessons will appear here after the admin adds them',
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
        title: Text(title.isEmpty ? 'Theory' : title),
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
                  if (level.isNotEmpty)
                    Text('Level: $level', style: const TextStyle(fontWeight: FontWeight.bold, color: purple)),
                  const SizedBox(height: 12),
                  if (description.isNotEmpty)
                    Text(description, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 16),
                  lectureText.trim().isEmpty
                      ? const Text('No theory available')
                      : MarkdownBody(
                    data: lectureText,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16, height: 1.5),
                      h2: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: purple),
                      h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      blockquote: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
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














