import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/auth_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  static const purple = Color(0xFF8E5BFF);

  late Map<String, dynamic> user;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    user = Map<String, dynamic>.from(widget.user);
  }

  String get _role => (user['role'] ?? 'USER').toString().toUpperCase();

  Future<void> _changeRole(String newRole) async {
    final current = _role;
    if (newRole == current) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Рөлді өзгерту'),
        content: Text('Қазір: $current\nЖаңа рөл: $newRole\n\nӨзгерте береміз бе?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Жоқ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Иә')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => loading = true);

    try {
      final token = await AuthService().getToken();
      if (token == null || token.isEmpty) {
        _toast('Token жоқ. Қайта login жаса.');
        if (mounted) setState(() => loading = false);
        return;
      }

      final id = (user['id'] ?? '').toString();
      if (id.isEmpty) {
        _toast('User id табылмады.');
        if (mounted) setState(() => loading = false);
        return;
      }

      final res = await http.patch(
        Uri.parse('${AuthService.baseUrl}/admin/users/$id/role'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"role": newRole}),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          setState(() => user = decoded);
        } else {
          setState(() => user['role'] = newRole);
        }

        _toast('Role өзгерді: $newRole');

        if (mounted) Navigator.pop(context, true); // ✅ refresh үшін
      } else {
        _toast('Қате: ${res.statusCode}\n${res.body}');
      }
    } catch (e) {
      _toast('Server error: $e');
    }

    if (mounted) setState(() => loading = false);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final username = (user['username'] ?? '—').toString();
    final email = (user['email'] ?? '—').toString();
    final level = (user['level'] ?? '').toString();
    final xp = (user['xp'] ?? 0).toString();
    final id = (user['id'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('User'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: purple.withOpacity(0.15),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(color: purple, fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 6),
                      Text(
                        'ID: #$id   •   Level: $level   •   XP: $xp',
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Role', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _roleChip(_role),
                    const Spacer(),
                    if (loading)
                      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading ? null : () => _changeRole('USER'),
                        child: const Text('USER'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white),
                        onPressed: loading ? null : () => _changeRole('ADMIN'),
                        child: const Text('ADMIN'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Удалить пользователя'),
                  subtitle: const Text('TODO: кейін қосамыз'),
                  onTap: () => _toast('Delete TODO (кейін)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Добавить (placeholder)'),
                  subtitle: const Text('TODO: кейін қосамыз'),
                  onTap: () => _toast('Add TODO (кейін)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: role == 'ADMIN' ? purple.withOpacity(0.12) : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: role == 'ADMIN' ? purple : Colors.black87,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}