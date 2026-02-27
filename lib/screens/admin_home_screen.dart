import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/screens/auth_screen.dart';
import 'package:kazakh_learning_app/screens/admin_users_screen.dart';
import 'package:kazakh_learning_app/screens/admin_task_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final String userName;
  const AdminHomeScreen({super.key, required this.userName});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const purple = Color(0xFF8E5BFF);
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AdminDashboardPage(
        userName: widget.userName,
        onGoUsers: () => setState(() => currentIndex = 1),
        onGoTasks: () => setState(() => currentIndex = 2),
        onGoModeration: () => setState(() => currentIndex = 3),
      ),
      const AdminUsersScreen(),
      const AdminTaskScreen(), // ✅ Tasks бөлек файлдан
      const AdminModerationScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        selectedItemColor: purple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt_outlined), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: ''),
        ],
      ),
    );
  }
}

/// ✅ Admin Dashboard (Scaffold жоқ!)
class AdminDashboardPage extends StatelessWidget {
  final String userName;
  final VoidCallback onGoUsers;
  final VoidCallback onGoTasks;
  final VoidCallback onGoModeration;

  const AdminDashboardPage({
    super.key,
    required this.userName,
    required this.onGoUsers,
    required this.onGoTasks,
    required this.onGoModeration,
  });

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Admin панель',
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
              const SizedBox(height: 14),

              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/Qoshqar.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$userName 👑',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _miniCard(title: 'Роль', value: 'Админ')),
                  const SizedBox(width: 12),
                  Expanded(child: _miniCard(title: 'Статус', value: 'Онлайн')),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ListView(
              children: [
                _actionCard(
                  title: 'Управление пользователями',
                  subtitle: 'Список всех пользователей',
                  icon: Icons.people_alt_outlined,
                  onTap: onGoUsers,
                ),
                _actionCard(
                  title: 'Tasks қосу / өшіру',
                  subtitle: 'Шариктер арқылы деңгей/тапсырма',
                  icon: Icons.task_alt_outlined,
                  onTap: onGoTasks,
                ),
                _actionCard(
                  title: 'Moderation (review)',
                  subtitle: 'Проверка/мониторинг ответов',
                  icon: Icons.shield_outlined,
                  onTap: onGoModeration,
                ),
              ],
            ),
          ),
        ),
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

  static Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminModerationScreen extends StatelessWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Moderation screen coming soon',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}