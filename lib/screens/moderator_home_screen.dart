import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/screens/auth_screen.dart';
import 'package:kazakh_learning_app/screens/moderator_users_screen.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';

class ModeratorHomeScreen extends StatefulWidget {
  final String userName;
  const ModeratorHomeScreen({super.key, required this.userName});

  @override
  State<ModeratorHomeScreen> createState() => _ModeratorHomeScreenState();
}

class _ModeratorHomeScreenState extends State<ModeratorHomeScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  int currentIndex = 0;

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
    final pages = [
      _ModeratorDashboard(
        userName: widget.userName,
        onLogout: () => _logout(context),
        onOpenUsers: () => setState(() => currentIndex = 1),
      ),
      const ModeratorUsersScreen(),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: purple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: ''),
        ],
      ),
    );
  }
}

class _ModeratorDashboard extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;
  final VoidCallback onOpenUsers;

  const _ModeratorDashboard({
    required this.userName,
    required this.onLogout,
    required this.onOpenUsers,
  });

  static const Color purple = Color(0xFF8E5BFF);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          height: 170,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: const BoxDecoration(
            color: purple,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(26),
              bottomRight: Radius.circular(26),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Moderator Panel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.logout, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$userName 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Модератор: тек қолданушыларды көреді',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Card -> Users (subtitle removed ✅)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: InkWell(
            onTap: onOpenUsers,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFE9DFFF),
                      child: Icon(Icons.people_alt_outlined, color: purple),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8), // closer to avatar
                    child: Text(
                      'Пользователи',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.chevron_right, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

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
                  'Moderator блоктар (кейін толтырамыз)',
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
}