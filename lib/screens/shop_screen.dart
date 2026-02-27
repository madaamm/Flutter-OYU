import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const purple = Color(0xFF8E5BFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Shop'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: const [
            _HeaderCard(),
            SizedBox(height: 16),

            _ShopItemCard(
              bg: Color(0xFFEAF3FF),
              border: Color(0xFFB9D6FF),
              iconBg: Color(0xFF2F80FF),
              icon: Icons.menu_book,
              title: 'Bonus Lesson',
              subtitle: 'Unlock a special advanced lesson',
              xp: '100 XP',
              buttonColor: Color(0xFF2F80FF),
            ),
            SizedBox(height: 14),

            _ShopItemCard(
              bg: Color(0xFFFFEEF3),
              border: Color(0xFFFFC1D3),
              iconBg: Color(0xFFFF4D87),
              icon: Icons.card_giftcard,
              title: 'Exclusive Content',
              subtitle: 'Cultural stories and songs',
              xp: '150 XP',
              buttonColor: Color(0xFFFF4D87),
            ),
            SizedBox(height: 14),

            _ShopItemCard(
              bg: Color(0xFFFFF9E6),
              border: Color(0xFFFFE19C),
              iconBg: Color(0xFFFFB300),
              icon: Icons.flash_on,
              title: 'Learning Booster',
              subtitle: 'Double XP for 24 hours',
              xp: '80 XP',
              buttonColor: Color(0xFFFFB300),
            ),
            SizedBox(height: 14),

            _ShopItemCard(
              bg: Color(0xFFF2E9FF),
              border: Color(0xFFD8C2FF),
              iconBg: Color(0xFF8E5BFF),
              icon: Icons.emoji_events,
              title: 'Premium Badge',
              subtitle: 'Exclusive profile badge',
              xp: '200 XP',
              buttonColor: Color(0xFF8E5BFF),
            ),
            SizedBox(height: 14),

            _ShopItemCard(
              bg: Color(0xFFEAF3FF),
              border: Color(0xFFB9D6FF),
              iconBg: Color(0xFF5D6BFF),
              icon: Icons.auto_stories,
              title: 'Cultural Pack',
              subtitle: 'Kazakh proverbs & traditions',
              xp: '120 XP',
              buttonColor: Color(0xFF5D6BFF),
            ),
            SizedBox(height: 14),

            _ShopItemCard(
              bg: Color(0xFFE6FBFF),
              border: Color(0xFFB6F1FF),
              iconBg: Color(0xFF00B8D9),
              icon: Icons.ac_unit,
              title: 'Streak Freeze',
              subtitle: 'Protect your streak for 3 days',
              xp: '90 XP',
              buttonColor: Color(0xFF00B8D9),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  static const purple = Color(0xFF8E5BFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        color: purple,
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.store, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Shop',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Redeem your points for rewards',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10),
          Text(
            '0 ⭐',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final Color bg;
  final Color border;
  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  final String xp;
  final Color buttonColor;

  const _ShopItemCard({
    required this.bg,
    required this.border,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(xp, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Redeem', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
