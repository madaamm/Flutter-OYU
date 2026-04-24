import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const Color purple = Color(0xFF6F159E);
  static const Color gold = Color(0xFFFFC400);
  static const Color silver = Color(0xFFC8D8DD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const Expanded(
                  child: Text(
                    'Shop',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 28),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Redeem your points for rewards',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                _Coin(color: gold),
                SizedBox(width: 6),
                Text('12', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(width: 12),
                _Coin(color: silver),
                SizedBox(width: 6),
                Text('6', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 42),
            const _ShopRewardCard(price: '12', coinColor: gold),
            SizedBox(height: 18),
            const _ShopRewardCard(price: '6', coinColor: silver),
            SizedBox(height: 18),
            const _ShopRewardCard(price: '12', coinColor: gold),
            SizedBox(height: 18),
            const _ShopRewardCard(price: '6', coinColor: silver),
            SizedBox(height: 18),
            const _ShopRewardCard(price: '12', coinColor: gold),
          ],
        ),
      ),
    );
  }
}

class _ShopRewardCard extends StatelessWidget {
  final String price;
  final Color coinColor;

  const _ShopRewardCard({
    required this.price,
    required this.coinColor,
  });

  static const Color purple = Color(0xFF6F159E);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 18),
      decoration: BoxDecoration(
        color: purple,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonus Book',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Unlock a special advanced lesson',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _Coin(color: coinColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
         SizedBox(
            width: 12,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BonusBookScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Redeem'),
            ),
          ),
        ],
      ),
    );
  }
}

class BonusBookScreen extends StatelessWidget {
  const BonusBookScreen({super.key});

  static const Color purple = Color(0xFF6F159E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: purple,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bonus Book',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Unlock a special advanced lesson',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 55),

                Container(
                  width: 170,
                  height: 260,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F0D8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 110,
                        decoration: const BoxDecoration(
                          color: Color(0xFF051D3A),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_stories,
                            color: Color(0xFFE0B94A),
                            size: 58,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'АБАЙ ЖОЛЫ',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'I кітап',
                        style: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Мұхтар Әуезов',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        color: const Color(0xFF051D3A),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                SizedBox(
                  width: 150,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Coin extends StatelessWidget {
  final Color color;
  final double size;

  const _Coin({
    required this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.pentagon_rounded,
      color: color,
      size: size,
      shadows: const [
        Shadow(
          color: Colors.black38,
          blurRadius: 1,
        ),
      ],
    );
  }
}