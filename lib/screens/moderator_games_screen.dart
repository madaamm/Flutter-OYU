import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/screens/moderator_games_crud_screen.dart';

class ModeratorGamesScreen extends StatefulWidget {
  const ModeratorGamesScreen({super.key});

  @override
  State<ModeratorGamesScreen> createState() => _ModeratorGamesScreenState();
}

class _ModeratorGamesScreenState extends State<ModeratorGamesScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  final PageController _controller = PageController(viewportFraction: 0.80);
  int index = 0;

  final List<_PracticeCardModel> items = const [
    _PracticeCardModel(
      title: 'Speaking',
      subtitle: 'improve your\nspeaking skills',
      cardColor: Color(0xFFB97CFF),
      sidePillColor: Color(0xFF5B2DBA),
      category: GameCategory.speaking,
    ),
    _PracticeCardModel(
      title: 'Reading',
      subtitle: 'improve your\nreading skills',
      cardColor: Color(0xFF4B007D),
      sidePillColor: Color(0xFFB97CFF),
      category: GameCategory.reading,
    ),
    _PracticeCardModel(
      title: 'Listening',
      subtitle: 'improve your\nlistening skills',
      cardColor: Color(0xFF4B007D),
      sidePillColor: Color(0xFFFFC107),
      category: GameCategory.listening,
    ),
    _PracticeCardModel(
      title: 'Writing',
      subtitle: 'improve your\nwriting skills',
      cardColor: Color(0xFFFFC107),
      sidePillColor: Color(0xFF4B007D),
      category: GameCategory.writing,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openCategory(GameCategory c) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ModeratorCategoryTasksEntryScreen(category: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            const Text(
              'Learn by practice',
              style: TextStyle(
                color: purple,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => index = i),
                itemBuilder: (context, i) {
                  final m = items[i];
                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: i == index ? 14 : 28,
                    ),
                    child: _PracticeCard(
                      model: m,
                      onStart: () => _openCategory(m.category),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: active ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? purple : Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _PracticeCardModel {
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color sidePillColor;
  final GameCategory category;

  const _PracticeCardModel({
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.sidePillColor,
    required this.category,
  });
}

class _PracticeCard extends StatelessWidget {
  final _PracticeCardModel model;
  final VoidCallback onStart;

  const _PracticeCard({
    required this.model,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -10,
          top: 18,
          bottom: 18,
          child: Container(
            width: 18,
            decoration: BoxDecoration(
              color: model.sidePillColor,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: model.cardColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    model.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    model.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 34,
                    width: 92,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}