import 'package:flutter/material.dart';
import 'speaking_screen.dart';
import 'reading_screen.dart';
import 'listening_screen.dart';

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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 10),
                  Text(
                    'Learn by practice',
                    style: TextStyle(
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
                children: const [
                  _GameCard(
                    title: 'Speaking',
                    subtitle: 'improve your speaking skills',
                    color1: Color(0xFFC96BFF),
                    color2: Color(0xFFB85CFF),
                  ),
                  _GameCard(
                    title: 'Reading',
                    subtitle: 'improve your reading skills',
                    color1: Color(0xFF6A00A8),
                    color2: Color(0xFF4B007A),
                  ),
                  _GameCard(
                    title: 'Listening',
                    subtitle: 'improve your listening skills',
                    color1: Color(0xFF4B007A),
                    color2: Color(0xFF26003D),
                  ),
                  _GameCard(
                    title: 'Writing',
                    subtitle: 'improve your writing skills',
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
  final String title;
  final String subtitle;
  final Color color1;
  final Color color2;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.color1,
    required this.color2,
  });

  void _openScreen(BuildContext context) {
    if (title == 'Speaking') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SpeakingScreen(),
        ),
      );
    }
    else if (title == 'Reading') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ReadingScreen(),
        ),
      );
    }
    else if (title == 'Listening') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ListeningScreen(),
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
              color: Colors.black.withOpacity(0.2),
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
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
