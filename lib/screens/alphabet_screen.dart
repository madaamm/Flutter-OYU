import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/screens/shop_screen.dart';


const purple = Color(0xFF8E5BFF);

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  // 16 карточка (дизайндағыдай)
  final List<_LetterItem> items = const [
    _LetterItem(letter: 'A', sound: '[a]'),
    _LetterItem(letter: 'Ә', sound: '[ä]'),
    _LetterItem(letter: 'Б', sound: '[b]'),
    _LetterItem(letter: 'В', sound: '[v]'),
    _LetterItem(letter: 'Г', sound: '[g]'),
    _LetterItem(letter: 'Ғ', sound: '[ğ]'),
    _LetterItem(letter: 'Д', sound: '[d]'),
    _LetterItem(letter: 'Е', sound: '[e]'),
    _LetterItem(letter: 'Ж', sound: '[zh]'),
    _LetterItem(letter: 'З', sound: '[z]'),
    _LetterItem(letter: 'И', sound: '[i]'),
    _LetterItem(letter: 'Й', sound: '[y]'),
    _LetterItem(letter: 'К', sound: '[k]'),
    _LetterItem(letter: 'Қ', sound: '[q]'),
    _LetterItem(letter: 'Л', sound: '[l]'),
    _LetterItem(letter: 'М', sound: '[m]'),
  ];

  // ✅ Басында бәрі lock болсын: 0
  int unlockedCount = 0;

  @override
  Widget build(BuildContext context) {
    final total = items.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(total: total),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16), // ✅ fix #2
                  itemCount: total,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final isUnlocked = index < unlockedCount;
                    final item = items[index];

                    return _LetterCard(
                      letter: item.letter,
                      sound: item.sound,
                      unlocked: isUnlocked,
                      onTap: () {
                        if (!isUnlocked) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Open ${item.letter} lesson')),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header({required int total}) {
    final progress = total == 0 ? 0.0 : (unlockedCount / total).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF8E5BFF), // ✅ fix #1 (const ішіне тікелей Color)
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
                  'Kazakh Alphabet  🔤',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Master all 42 letters',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your Progress',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    Text(
                      '$unlockedCount/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.35),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.black87),
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

class _LetterCard extends StatelessWidget {
  final String letter;
  final String sound;
  final bool unlocked;
  final VoidCallback onTap;

  static const greenCard = Color(0xFF00C853);

  const _LetterCard({
    required this.letter,
    required this.sound,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = unlocked ? greenCard : const Color(0xFFBDBDBD);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            if (unlocked)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16),
                ),
              ),
            Center(
              child: unlocked
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    letter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sound,
                    style:
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              )
                  : const Icon(Icons.lock, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterItem {
  final String letter;
  final String sound;
  const _LetterItem({required this.letter, required this.sound});
}
