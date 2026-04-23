import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/screens/admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const purple = Color(0xFF8E5BFF);

  bool _loading = true;
  String? _error;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await AuthService().getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Token табылмады. Қайта login жаса.';
          _loading = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = (decoded is List) ? decoded : <dynamic>[];
        setState(() {
          _users = list;
          _loading = false;
        });
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        setState(() {
          _error = 'Рұқсат жоқ (admin token керек).';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Қате: ${res.statusCode}\n${res.body}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Server error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchUsers,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Users басқару',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          IconButton(
            onPressed: _fetchUsers,
            icon: const Icon(Icons.refresh, color: purple),
          ),
        ],
      ),
    );

    if (_loading) {
      return ListView(
        children: [
          header,
          const SizedBox(height: 120),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          header,
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _error!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchUsers,
            child: const Text('Қайта жүктеу'),
          ),
        ],
      );
    }

    if (_users.isEmpty) {
      return ListView(
        children: [
          header,
          const SizedBox(height: 120),
          const Center(child: Text('Users жоқ')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      itemCount: _users.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return header;

        final raw = _users[index - 1];
        final u = (raw is Map<String, dynamic>) ? raw : Map<String, dynamic>.from(raw as Map);

        final id = (u['id'] ?? '').toString();
        final username = (u['username'] ?? '—').toString();
        final email = (u['email'] ?? '—').toString();
        final role = (u['role'] ?? 'USER').toString();
        final level = (u['level'] ?? '').toString();
        final xp = (u['xp'] ?? 0).toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: purple.withOpacity(0.15),
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(color: purple, fontWeight: FontWeight.w900),
                ),
              ),
              title: Text('$username  ($id)', style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('$email\nrole: $role   level: $level   xp: $xp'),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminUserDetailScreen(user: u)),
                );
                if (changed == true) _fetchUsers();
              },
            ),
          ),
        );
      },
    );
  }
}