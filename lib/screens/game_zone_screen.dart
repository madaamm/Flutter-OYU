import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/l10n/app_text.dart';
import 'speaking_screen.dart';
import 'reading_screen.dart';
import 'listening_screen.dart';
import 'writing_screen.dart';

class GameZoneScreen extends StatelessWidget {
  const GameZoneScreen({super.key});

  static const purple = Color(0xFF3D0067);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D0067),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: const BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    context.tr('learn_by_practice'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // CAROUSEL
            Expanded(
              child: PageView(
                controller: PageController(viewportFraction: 0.85),
                children: [
                  _GameCard(
                    routeKey: 'speaking',
                    title: context.tr('speaking'),
                    subtitle: context.tr('improve_speaking'),
                    color1: Color(0xFFC96BFF),
                    color2: Color(0xFFB85CFF),
                  ),
                  _GameCard(
                    routeKey: 'reading',
                    title: context.tr('reading'),
                    subtitle: context.tr('improve_reading'),
                    color1: Color(0xFF6A00A8),
                    color2: Color(0xFF4B007A),
                  ),
                  _GameCard(
                    routeKey: 'listening',
                    title: context.tr('listening'),
                    subtitle: context.tr('improve_listening'),
                    color1: Color(0xFF4B007A),
                    color2: Color(0xFF26003D),
                  ),
                  _GameCard(
                    routeKey: 'writing',
                    title: context.tr('writing'),
                    subtitle: context.tr('improve_writing'),
                    color1: Color(0xFFFFC400),
                    color2: Color(0xFFFFB300),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String routeKey;
  final String title;
  final String subtitle;
  final Color color1;
  final Color color2;

  const _GameCard({
    required this.routeKey,
    required this.title,
    required this.subtitle,
    required this.color1,
    required this.color2,
  });

  void _openScreen(BuildContext context) {
    if (routeKey == 'speaking') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SpeakingScreen(),
        ),
      );
    }
    else if (routeKey == 'reading') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ReadingScreen(),
        ),
      );
    }
    else if (routeKey == 'listening') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ListeningScreen(),
        ),
      );
    }
    else if (routeKey == 'writing') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const WritingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => _openScreen(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
                child: Text(context.tr('start')),
              ),
          ],
        ),
      ),
    );
  }
}
