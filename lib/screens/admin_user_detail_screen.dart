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
  bool deleting = false;

  @override
  void initState() {
    super.initState();
    user = Map<String, dynamic>.from(widget.user);
  }

  String get _role => (user['role'] ?? 'USER').toString().trim().toUpperCase();

  Map<String, dynamic> _safeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  // ✅ PUT /admin/users/:id/role
  Future<void> _changeRole(String newRole) async {
    final current = _role;
    if (newRole == current) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Рөлді өзгерту'),
        content: Text('Қазір: $current\nЖаңа рөл: $newRole\n\nӨзгерте береміз бе?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Жоқ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Иә'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => loading = true);

    try {
      final token = await AuthService().getToken();
      if (token == null || token.isEmpty) {
        _toast('Token жоқ. Қайта login жаса.');
        return;
      }

      final id = (user['id'] ?? '').toString().trim();
      if (id.isEmpty) {
        _toast('User id табылмады.');
        return;
      }

      // ✅ дұрыс endpoint
      final url = '${AuthService.baseUrl}/admin/users/$id/role';
      debugPrint('ROLE PUT => $url');

      final res = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"role": newRole}), // USER / MODERATOR / ADMIN
      );

      if (res.statusCode == 200) {
        final decoded = _safeJsonMap(res.body);

        // backend кейде { user: {...} } қайтарады
        final updatedUser =
        (decoded['user'] is Map) ? Map<String, dynamic>.from(decoded['user']) : decoded;

        if (updatedUser.isNotEmpty) {
          setState(() => user = updatedUser);
        } else {
          setState(() => user['role'] = newRole);
        }

        _toast('Role өзгерді: $newRole');
        if (mounted) Navigator.pop(context, true); // ✅ list refresh
      } else {
        _toast('Қате: ${res.statusCode}\n${res.body}');
      }
    } catch (e) {
      _toast('Server error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ✅ DELETE /admin/users/:id
  Future<void> _deleteUser() async {
    final targetId = (user['id'] ?? '').toString().trim();
    if (targetId.isEmpty) {
      _toast('User id табылмады.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Пайдаланушыны өшіру'),
        content: Text(
          'ID: #$targetId\n'
              'Бұл әрекет қайтарылмайды.\n\n'
              'Өшіреміз бе?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Жоқ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Иә, өшіру'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => deleting = true);

    try {
      final token = await AuthService().getToken();
      if (token == null || token.isEmpty) {
        _toast('Token жоқ. Қайта login жаса.');
        return;
      }

      final url = '${AuthService.baseUrl}/admin/users/$targetId';
      debugPrint('DELETE USER => $url');

      final res = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        if (!mounted) return;
        _toast('User өшірілді');
        Navigator.pop(context, true); // ✅ list refresh
        return;
      }

      _toast('Қате: ${res.statusCode}\n${res.body}');
    } catch (e) {
      _toast('Server error: $e');
    } finally {
      if (mounted) setState(() => deleting = false);
    }
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
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

                // ✅ USER / MODERATOR / ADMIN
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (loading || deleting) ? null : () => _changeRole('USER'),
                        child: const Text('USER'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (loading || deleting) ? null : () => _changeRole('MODERATOR'),
                        child: const Text('MODERATOR'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white),
                        onPressed: (loading || deleting) ? null : () => _changeRole('ADMIN'),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Удалить пользователя'),
                  subtitle: const Text('Admin: user өшіру'),
                  enabled: !(deleting || loading),
                  onTap: (deleting || loading) ? null : _deleteUser,
                  trailing: deleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.3))
                      : null,
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
    final isAdmin = role == 'ADMIN';
    final isMod = role == 'MODERATOR';

    final bg = (isAdmin || isMod) ? purple.withOpacity(0.12) : Colors.black.withOpacity(0.06);
    final fg = (isAdmin || isMod) ? purple : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900),
      ),
    );
  }
}