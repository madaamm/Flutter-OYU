import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:kazakh_learning_app/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;

  const ProfileScreen({super.key, required this.userName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const purple = Color(0xFF8E5BFF);

  bool loading = true;
  bool savingNick = false;
  bool savingName = false;
  String? error;

  String nickname = '';
  int xp = 0;
  String level = '';
  int userId = 0;

  // ✅ Full name (backend: username) — Profile ішінде көрсетілетін
  late String _fullName;

  Map<String, dynamic> _safeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    _fullName = widget.userName;
    _loadMe();
  }

  Future<void> _loadMe() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final me = await AuthService().me(); // GET /api/user/me

      final idRaw = me['id'];
      final uid = (idRaw is int) ? idRaw : int.tryParse(idRaw.toString()) ?? 0;

      // ✅ Full name backend-та username деп тұр
      final usernameFromApi =
      (me['username'] ?? me['user']?['username'] ?? '').toString().trim();

      if (uid > 0) {
        userId = uid;
        await AuthService().saveUserId(uid);

        // ✅ username кешке сақтау + Profile-де көрсету
        if (usernameFromApi.isNotEmpty) {
          await AuthService().saveUsernameForUser(uid, usernameFromApi);
          _fullName = usernameFromApi;
        } else {
          final cached = await AuthService().getUsernameForUser(uid);
          if (cached != null && cached.trim().isNotEmpty) {
            _fullName = cached.trim();
          }
        }
      }

      // ✅ Nickname
      final nickFromApi = (me['nickname'] ?? '').toString().trim();
      final cachedNick = (uid > 0)
          ? ((await AuthService().getNicknameForUser(uid))?.trim() ?? '')
          : '';

      final finalNick = nickFromApi.isNotEmpty ? nickFromApi : cachedNick;

      if (uid > 0 && nickFromApi.isNotEmpty) {
        await AuthService().saveNicknameForUser(uid, nickFromApi);
      }

      setState(() {
        nickname = finalNick;
        xp = (me['xp'] ?? 0) is int ? (me['xp'] ?? 0) : int.tryParse('${me['xp']}') ?? 0;
        level = (me['level'] ?? '').toString();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'ME error: $e';
        loading = false;
      });
    }
  }

  // ================= Nickname =================

  Future<bool?> _checkNicknameAvailable(String nick) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      _toast('Token жоқ. Қайта login жаса.');
      return null;
    }

    final uri = Uri.parse('${AuthService.baseUrl}/user/nickname/check')
        .replace(queryParameters: {'nickname': nick});

    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (res.statusCode == 200) {
      final decoded = _safeJsonMap(res.body);
      final available = decoded['available'];
      if (available is bool) return available;
      return null;
    }

    _toast('Check error: ${res.statusCode}\n${res.body}');
    return null;
  }

  Future<void> _updateNickname(String newNick) async {
    if (savingNick) return;

    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      _toast('Token жоқ. Қайта login жаса.');
      return;
    }

    setState(() => savingNick = true);

    try {
      final res = await http.patch(
        Uri.parse('${AuthService.baseUrl}/user/me/nickname'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"nickname": newNick}),
      );

      if (res.statusCode == 200) {
        final decoded = _safeJsonMap(res.body);
        final updatedNick = (decoded['nickname'] ?? newNick).toString().trim();

        setState(() => nickname = updatedNick);

        final uid = userId > 0 ? userId : (await AuthService().getUserId() ?? 0);
        if (uid > 0) {
          await AuthService().saveNicknameForUser(uid, updatedNick);
        }

        _toast('Nickname сақталды: $updatedNick');
        return;
      }

      if (res.statusCode == 409) {
        final decoded = _safeJsonMap(res.body);
        final updatedNick = (decoded['nickname'] ?? '').toString().trim();

        if (updatedNick.isNotEmpty) {
          setState(() => nickname = updatedNick);

          final uid = userId > 0 ? userId : (await AuthService().getUserId() ?? 0);
          if (uid > 0) {
            await AuthService().saveNicknameForUser(uid, updatedNick);
          }

          _toast('Бұл nickname бос емес. Жаңа nickname: $updatedNick');
        } else {
          _toast('Nickname бос емес (409)');
        }
        return;
      }

      _toast('Қате: ${res.statusCode}\n${res.body}');
    } catch (e) {
      _toast('Server error: $e');
    } finally {
      if (mounted) setState(() => savingNick = false);
    }
  }

  Future<void> _openChangeNickname() async {
    final controller = TextEditingController(text: nickname);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nickname өзгерту'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'new_nick_123'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Жабу')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сақтау')),
        ],
      ),
    );

    if (ok != true) return;

    final newNick = controller.text.trim();
    if (newNick.isEmpty) {
      _toast('Nickname бос болмауы керек');
      return;
    }

    final available = await _checkNicknameAvailable(newNick);
    if (available == false) {
      _toast('Ондай nickname бос емес');
      return;
    }

    await _updateNickname(newNick);
  }

  // ================= Full name (username) =================

  Future<void> _openChangeFullName() async {
    if (savingName) return;

    final controller = TextEditingController(text: _fullName);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Атыңды өзгерту'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Full name (2-50 символ)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Жабу')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сақтау')),
        ],
      ),
    );

    if (ok != true) return;

    final newName = controller.text.trim();
    if (newName.isEmpty) {
      _toast('Аты бос болмауы керек');
      return;
    }

    setState(() => savingName = true);

    try {
      final res = await AuthService().updateUsername(newName);

      if (res['ok'] == true) {
        final updated = (res['username'] ?? newName).toString().trim();
        setState(() => _fullName = updated);
        _toast('Аты сақталды: $updated');
      } else {
        _toast((res['message'] ?? 'Қате').toString());
      }
    } catch (e) {
      _toast('Server error: $e');
    } finally {
      if (mounted) setState(() => savingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F1FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F1FF),
        appBar: AppBar(backgroundColor: purple, title: const Text('Profile')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(error!, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadMe, child: const Text('Қайта жүктеу')),
            ],
          ),
        ),
      );
    }

    // ✅ display name: nickname бар болса nickname, болмаса full name
    final displayName = nickname.isNotEmpty ? nickname : _fullName;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('Profile'),
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
                  radius: 28,
                  backgroundColor: purple.withOpacity(0.15),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        'Full name: ${_fullName.isNotEmpty ? _fullName : '—'}',
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nickname: ${nickname.isNotEmpty ? nickname : '—'}',
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Level: ${level.isNotEmpty ? level : '—'}  •  XP: $xp',
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ✅ Full name өзгерту
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: savingName ? null : _openChangeFullName,
              icon: savingName
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.3))
                  : const Icon(Icons.badge_outlined),
              label: const Text('Атын өзгерту'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ Nickname өзгерту
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: savingNick ? null : _openChangeNickname,
              icon: savingNick
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.3))
                  : const Icon(Icons.edit),
              label: const Text('Nickname өзгерту'),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}