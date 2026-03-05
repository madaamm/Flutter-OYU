import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/screens/moderator_user_detail_screen.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';

class ModeratorUsersScreen extends StatefulWidget {
  const ModeratorUsersScreen({super.key});

  @override
  State<ModeratorUsersScreen> createState() => _ModeratorUsersScreenState();
}

class _ModeratorUsersScreenState extends State<ModeratorUsersScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  bool loading = true;
  String? error;
  List<dynamic> users = [];

  Map<String, dynamic> _safeMap(String body) {
    try {
      final d = jsonDecode(body);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {};
  }

  List<dynamic> _safeList(String body) {
    try {
      final d = jsonDecode(body);
      if (d is List) return d;
    } catch (_) {}
    return [];
  }

  void _showError(String msg) {
    // SnackBar: тек error үшін
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await AuthService().getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          error = 'Token жоқ. Қайта login жаса.';
          loading = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        setState(() {
          users = _safeList(res.body);
          loading = false;
        });
        return;
      }

      final m = _safeMap(res.body);
      setState(() {
        error = (m['message'] ?? 'Қате: ${res.statusCode}').toString();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Server error: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: purple,
          title: const Text('Пользователи'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(error!, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loadUsers,
                child: const Text('Қайта жүктеу'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('Пользователи'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final u = (users[i] is Map)
              ? Map<String, dynamic>.from(users[i] as Map)
              : <String, dynamic>{};

          final id = (u['id'] ?? '').toString();
          final username = (u['username'] ?? '—').toString();
          final email = (u['email'] ?? '—').toString();
          final role = (u['role'] ?? 'USER').toString().toUpperCase();

          return InkWell(
            onTap: () {
              if (id.isEmpty) {
                _showError('User id жоқ');
                return;
              }

              // ✅ IMPORTANT: always root navigator
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => ModeratorUserDetailScreen(userId: id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: purple.withOpacity(0.15),
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: purple,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 6),
                        _roleChip(role),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black45),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _roleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: purple.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: const TextStyle(color: purple, fontWeight: FontWeight.w900),
      ),
    );
  }
}