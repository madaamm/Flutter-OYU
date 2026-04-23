import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/screens/home_screen.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';

class ScenarioSelectScreen extends StatefulWidget {
  final String userName;
  final String email;

  const ScenarioSelectScreen({
    super.key,
    required this.userName,
    required this.email,
  });

  @override
  State<ScenarioSelectScreen> createState() => _ScenarioSelectScreenState();
}

class _ScenarioSelectScreenState extends State<ScenarioSelectScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color deepPurple = Color(0xFF6D2DFF);

  final _auth = AuthService();

  int? _selectedIndex;
  bool _saving = false;

  final List<_ScenarioItem> _items = const [
    _ScenarioItem(icon: Icons.flight_takeoff, title: 'Prepare for travel'),
    _ScenarioItem(icon: Icons.airplane_ticket, title: 'At the airport (Check-in)'),
    _ScenarioItem(icon: Icons.restaurant, title: 'Ordering food in a cafe'),
    _ScenarioItem(icon: Icons.chat_bubble_outline, title: 'Daily greetings & small talk'),
    _ScenarioItem(icon: Icons.shopping_bag_outlined, title: 'Shopping for clothes'),
    _ScenarioItem(icon: Icons.support_agent, title: 'Asking for help (Emergency)'),
  ];

  Future<void> _continue() async {
    if (_selectedIndex == null || _saving) return;

    setState(() => _saving = true);

    try {
      await _auth.setScenarioShownForEmail(widget.email, true);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(userName: widget.userName),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedIndex != null && !_saving;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 170,
              decoration: const BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Qoshqar.png',
                      height: 54,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'OYU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: canContinue ? 0.22 : 0.0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE6E6E6),
                        valueColor: const AlwaysStoppedAnimation<Color>(deepPurple),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Select one of the scenario below',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          final selected = _selectedIndex == i;

                          return InkWell(
                            onTap: () => setState(() => _selectedIndex = i),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? deepPurple
                                      : const Color(0xFFDDDDDD),
                                  width: selected ? 1.6 : 1.0,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 14,
                                    offset: Offset(0, 8),
                                    color: Color(0x0F000000),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF3FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: Colors.blue,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: canContinue ? _continue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deepPurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE9E3FF),
                          disabledForegroundColor: Colors.white70,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _ScenarioItem {
  final IconData icon;
  final String title;

  const _ScenarioItem({
    required this.icon,
    required this.title,
  });
}