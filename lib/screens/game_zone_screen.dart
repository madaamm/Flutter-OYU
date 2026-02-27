import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/screens/shop_screen.dart';

class GameZoneScreen extends StatelessWidget {
  const GameZoneScreen({super.key});

  static const purple = Color(0xFF8E5BFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: Column(
          children: [

            // ===== HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
              decoration: const BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [

                      const Expanded(
                        child: Text(
                          'Game Zone 🎮',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      // 👉 SHOP BUTTON
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.store, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShopScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    '2.3.4',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: const [

                      Expanded(
                        child: _TopStatCard(
                          icon: '🏆',
                          title: 'Total Score',
                          value: '0',
                        ),
                      ),

                      SizedBox(width: 14),

                      Expanded(
                        child: _TopStatCard(
                          icon: '⭐',
                          title: 'Games Won',
                          value: '0',
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Practice by Skill',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===== PRACTICE LIST =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: const [

                  _PracticeCard(
                    color: Color(0xFFFFE5E5),
                    iconBg: Color(0xFFFF4D4D),
                    icon: Icons.mic,
                    title: 'Speaking',
                    subtitle: 'Practice pronunciation',
                    progressText: '0/15 games',
                    buttonText: 'Start Practicing',
                  ),

                  SizedBox(height: 14),

                  _PracticeCard(
                    color: Color(0xFFEAF3FF),
                    iconBg: Color(0xFF2F80FF),
                    icon: Icons.menu_book,
                    title: 'Reading',
                    subtitle: 'Match words with images',
                    progressText: '0/15 games',
                    buttonText: 'Start Practicing',
                  ),

                  SizedBox(height: 14),

                  _PracticeCard(
                    color: Color(0xFFE9FFF3),
                    iconBg: Color(0xFF00C853),
                    icon: Icons.headphones,
                    title: 'Listening',
                    subtitle: 'Identify correct words',
                    progressText: '0/15 games',
                    buttonText: 'Start Practicing',
                  ),

                  SizedBox(height: 14),

                  _PracticeCard(
                    color: Color(0xFFF2E9FF),
                    iconBg: Color(0xFF8E5BFF),
                    icon: Icons.edit,
                    title: 'Writing',
                    subtitle: 'Type and trace letters',
                    progressText: '0/15 games',
                    buttonText: 'Start Practicing',
                  ),

                  SizedBox(height: 18),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== TOP STAT CARD =====

class _TopStatCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;

  const _TopStatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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

// ===== PRACTICE CARD =====

class _PracticeCard extends StatelessWidget {
  final Color color;
  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  final String progressText;
  final String buttonText;

  const _PracticeCard({
    required this.color,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progressText,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: iconBg.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progress',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              Text(
                progressText,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0,
              minHeight: 8,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(iconBg),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: iconBg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
