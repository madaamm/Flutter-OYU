import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/screens/shop_screen.dart';


class ProfileScreen extends StatelessWidget {
  final String userName;

  const ProfileScreen({super.key, required this.userName});

  static const purple = Color(0xFF8E5BFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 16),
              _statsRow(),
              const SizedBox(height: 18),
              _badgesGrid(),
              const SizedBox(height: 18),
              _leaderboard(),
              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Compete Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: purple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            // Егер avatar.png жоқ болса, мына жолды коммент қылып қой:
            // backgroundImage: AssetImage('assets/images/avatar.png'),
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Beginner Learner',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.settings, color: Colors.white),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(child: _StatCard(title: 'Total XP', value: '0')),
          SizedBox(width: 12),
          Expanded(child: _StatCard(title: 'Badges', value: '0')),
          SizedBox(width: 12),
          Expanded(child: _StatCard(title: 'Day Streak', value: '0')),
        ],
      ),
    );
  }

  Widget _badgesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: const [
          _Badge('🔥', 'Week Streak'),
          _Badge('⭐', 'First Letter'),
          _Badge('🏆', 'Quiz Master'),
          _Badge('📚', 'Bookworm'),
          _Badge('🎯', 'Sharp Shooter', locked: true),
          _Badge('💎', 'Diamond League', locked: true),
        ],
      ),
    );
  }

  Widget _leaderboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.public, size: 18, color: purple),
              SizedBox(width: 8),
              Text(
                'World Records',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: purple.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                const _LeaderboardRow(
                  leftIcon: Icons.emoji_events,
                  leftIconColor: Color(0xFFFFB300),
                  avatar: 'https://i.pravatar.cc/150?img=12',
                  name: 'Nurlan K.',
                  country: 'KZ',
                  points: '15 420',
                ),
                const _DividerLine(),
                const _LeaderboardRow(
                  leftIcon: Icons.emoji_events,
                  leftIconColor: Color(0xFFB0B0B0),
                  avatar: 'https://i.pravatar.cc/150?img=32',
                  name: 'Assel M.',
                  country: 'KZ',
                  points: '14 850',
                ),
                const _DividerLine(),
                const _LeaderboardRow(
                  leftIcon: Icons.emoji_events,
                  leftIconColor: Color(0xFFB26A00),
                  avatar: 'https://i.pravatar.cc/150?img=8',
                  name: 'Dias A.',
                  country: 'KZ',
                  points: '14 230',
                ),
                const _DividerLine(),

                _LeaderboardRow(
                  isYou: true,
                  rankText: '#15',
                  avatar: 'https://i.pravatar.cc/150?img=5',
                  name: 'You ($userName)',
                  country: 'KZ',
                  points: '0',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String icon;
  final String title;
  final bool locked;

  const _Badge(this.icon, this.title, {this.locked = false});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8E5BFF);

    return Container(
      decoration: BoxDecoration(
        color: locked ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purple.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: locked ? Colors.grey : purple,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final bool isYou;
  final String? rankText;

  final IconData? leftIcon;
  final Color? leftIconColor;

  final String avatar;
  final String name;
  final String country;
  final String points;

  const _LeaderboardRow({
    this.isYou = false,
    this.rankText,
    this.leftIcon,
    this.leftIconColor,
    required this.avatar,
    required this.name,
    required this.country,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8E5BFF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isYou ? const Color(0xFFEDE3FF) : Colors.transparent,
        borderRadius: isYou ? BorderRadius.circular(14) : BorderRadius.zero,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Center(
              child: isYou
                  ? Text(
                rankText ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                ),
              )
                  : Icon(leftIcon, color: leftIconColor, size: 26),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            backgroundImage: NetworkImage(avatar),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  country,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                points,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: purple,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'points',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0x1A000000));
  }
}
