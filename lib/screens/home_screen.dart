import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/screens/alphabet_screen.dart';
import 'package:kazakh_learning_app/screens/ask_ai_screen.dart';
import 'package:kazakh_learning_app/screens/game_zone_screen.dart';
import 'package:kazakh_learning_app/screens/profile_screen.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/screens/auth_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const purple = Color(0xFF8E5BFF);

  int currentIndex = 0;

  final _auth = AuthService();
  String _name = 'User';

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    // бастапқыда login-нан келген ат тұрады
    _name = widget.userName;

    // pages бастапқы құрылады
    pages = _buildPages();

    // кейін кештен (username_u_<id>) оқып жаңартамыз
    _loadNameFromCache();
  }

  List<Widget> _buildPages() {
    return [
      HomePage(userName: _name),
      const AlphabetScreen(),
      const AskAiScreen(),
      const GameZoneScreen(),
      ProfileScreen(userName: _name),
    ];
  }

  Future<void> _loadNameFromCache() async {
    final cached = await _auth.getCachedUsernameOrDefault();
    if (!mounted) return;

    // егер кеште "User" немесе бос емес нақты ат болса — жаңартамыз
    if (cached.trim().isNotEmpty && cached.trim() != _name.trim()) {
      setState(() {
        _name = cached.trim();
        pages = _buildPages(); // маңызды: pages қайта құру
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) async {
          setState(() => currentIndex = index);

          // ✅ әр tab ауысқанда кештен қайта оқимыз
          await _loadNameFromCache();
        },
        selectedItemColor: purple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}

/// ✅ Home беттегі негізгі контент (Scaffold ЖОҚ!)
class HomePage extends StatelessWidget {
  final String userName;
  const HomePage({super.key, required this.userName});

  static const purple = Color(0xFF8E5BFF);

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ Top purple block
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
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
              // ✅ Logout кнопка
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Сәлем, Hello!',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  InkWell(
                    onTap: () => _logout(context),
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.logout, color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                '$userName 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _miniCard(title: 'Score', value: '0 ⭐')),
                  const SizedBox(width: 12),
                  Expanded(child: _miniCard(title: 'Level', value: 'Beginner')),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ✅ Progress card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Learning Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text('0%'),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: 0,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _smallStat('Letters Learned', '0/42')),
                    const SizedBox(width: 12),
                    Expanded(child: _smallStat('Words Learned', '0')),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ✅ Big menu placeholder
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Text(
                  'Меню блок (кейін толтырамыз)',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  static Widget _miniCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _smallStat(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: purple)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}