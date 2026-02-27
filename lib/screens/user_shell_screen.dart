import 'package:flutter/material.dart';

import 'package:kazakh_learning_app/screens/home_screen.dart';
import 'package:kazakh_learning_app/screens/alphabet_screen.dart';
import 'package:kazakh_learning_app/screens/ask_ai_screen.dart';
import 'package:kazakh_learning_app/screens/game_zone_screen.dart';
import 'package:kazakh_learning_app/screens/profile_screen.dart';

class UserShellScreen extends StatefulWidget {
  final String userName;
  const UserShellScreen({super.key, required this.userName});

  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  static const Color deepPurple = Color(0xFF6D2DFF);

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      // Home
      HomeScreen(userName: widget.userName),

      // Aa (Alphabet)
      const AlphabetScreen(),

      // ✅ AI (МІНЕ ОСЫ ЖЕР — placeholder емес, нақты AskAiScreen)
      const AskAiScreen(),

      // Game
      const GameZoneScreen(),

      // Profile
      ProfileScreen(userName: widget.userName),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, -8),
              color: Color(0x14000000),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: deepPurple,
          unselectedItemColor: Colors.black38,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'Aa'),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'AI'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_esports_outlined), label: 'Game'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}