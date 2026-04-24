import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/screens/shop_screen.dart';
import 'package:kazakh_learning_app/services/follow_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;

  const ProfileScreen({super.key, required this.userName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color deepPurple = Color(0xFF6D2DFF);
  static const Color bg = Color(0xFFF6F1FF);
  static const Color card = Colors.white;

  bool loading = true;
  bool savingNick = false;
  bool savingName = false;
  String? error;

  String nickname = '';
  String email = '';
  int xp = 0;
  String level = '';
  int userId = 0;

  late String _fullName;

  final FollowService _follow = FollowService();
  FollowCounts? _counts;
  bool _countsLoading = true;

  Map<String, dynamic> _safeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  void _errorSnack(String msg) {
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
      _countsLoading = true;
    });

    try {
      final me = await AuthService().me();

      final idRaw = me['id'];
      final uid = (idRaw is int) ? idRaw : int.tryParse(idRaw.toString()) ?? 0;

      final usernameFromApi =
      (me['username'] ?? me['user']?['username'] ?? '').toString().trim();

      if (uid > 0) {
        userId = uid;
        await AuthService().saveUserId(uid);

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

      final nickFromApi = (me['nickname'] ?? '').toString().trim();
      final cachedNick = (uid > 0)
          ? ((await AuthService().getNicknameForUser(uid))?.trim() ?? '')
          : '';

      final finalNick = nickFromApi.isNotEmpty ? nickFromApi : cachedNick;

      if (uid > 0 && nickFromApi.isNotEmpty) {
        await AuthService().saveNicknameForUser(uid, nickFromApi);
      }

      FollowCounts? c;
      if (uid > 0) {
        try {
          c = await _follow.getCounts(uid);
        } catch (_) {}
      }

      setState(() {
        nickname = finalNick;
        email = (me['email'] ?? me['user']?['email'] ?? '').toString().trim();
        xp = (me['xp'] ?? 0) is int ? (me['xp'] ?? 0) : int.tryParse('${me['xp']}') ?? 0;
        level = (me['level'] ?? 'A0').toString();
        _counts = c;
        loading = false;
        _countsLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'ME error: $e';
        loading = false;
        _countsLoading = false;
      });
    }
  }

  Future<bool?> _checkNicknameAvailable(String nick) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      _errorSnack('Token жоқ. Қайта login жаса.');
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

    _errorSnack('Check error: ${res.statusCode}');
    return null;
  }

  Future<void> _updateNickname(String newNick) async {
    if (savingNick) return;

    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      _errorSnack('Token жоқ. Қайта login жаса.');
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
        } else {
          _errorSnack('Nickname бос емес (409)');
        }
        return;
      }

      _errorSnack('Қате: ${res.statusCode}');
    } catch (e) {
      _errorSnack('Server error: $e');
    } finally {
      if (mounted) setState(() => savingNick = false);
    }
  }

  Future<void> _openChangeNickname() async {
    final controller = TextEditingController(text: nickname);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Nickname өзгерту'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'new_nick_123',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Жабу'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: purple),
            child: const Text('Сақтау'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final newNick = controller.text.trim();
    if (newNick.isEmpty) {
      _errorSnack('Nickname бос болмауы керек');
      return;
    }

    final available = await _checkNicknameAvailable(newNick);
    if (available == false) {
      _errorSnack('Ондай nickname бос емес');
      return;
    }

    await _updateNickname(newNick);
  }

  void _openBioData() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BioDataScreen(
          fullName: _fullName,
          nickname: nickname,
          level: level.isNotEmpty ? level : 'A0',
          email: email,
          onSaveName: (value) async {
            final res = await AuthService().updateUsername(value);
            if (res['ok'] == true) {
              setState(() => _fullName = (res['username'] ?? value).toString().trim());
            } else {
              throw Exception((res['message'] ?? 'Қате').toString());
            }
          },
          onSaveNickname: (value) async {
            final available = await _checkNicknameAvailable(value);
            if (available == false) {
              throw Exception('Ондай nickname бос емес');
            }
            await _updateNickname(value);
          },
        ),
      ),
    ).then((_) => _loadMe());
  }

  Future<void> _openInviteSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteSearchSheet(
        myUserId: userId,
        myNickname: nickname,
        myUsername: _fullName,
        followService: _follow,
      ),
    );

    await _loadMe();
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  error!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadMe,
                  style: ElevatedButton.styleFrom(backgroundColor: purple),
                  child: const Text('Қайта жүктеу'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final displayName = nickname.isNotEmpty ? nickname : _fullName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final followingCount = _countsLoading ? '—' : '${_counts?.followingCount ?? 0}';
    final followersCount = _countsLoading ? '—' : '${_counts?.followersCount ?? 0}';
    final progress = ((xp % 1000) / 1000).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: purple,
          onRefresh: _loadMe,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_back, color: Colors.transparent),
                  ),
                  const Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF252525),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: purple.withOpacity(0.13),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: purple,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF232323),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${nickname.isNotEmpty ? nickname : _fullName.toLowerCase().replaceAll(' ', '_')} • Joined 2025',
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _openBioData,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EDFF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(Icons.edit, color: Color(0xFF232323), size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _pill(
                          text: level.isNotEmpty ? level : 'A0',
                          filled: false,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _topStat(
                            title: 'Following',
                            value: followingCount,
                            onTap: () {
                              if (userId <= 0) return;
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => FollowingListScreen(userId: userId),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(width: 1, height: 34, color: Colors.black12),
                        Expanded(
                          child: _topStat(
                            title: 'Followers',
                            value: followersCount,
                            onTap: () {
                              if (userId <= 0) return;
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => FollowersListScreen(userId: userId),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _openInviteSheet,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFA348FF), Color(0xFF7441CC)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'INVITE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _roundAction(
                          icon: Icons.badge_outlined,
                          onTap: _openBioData,
                        ),
                        const SizedBox(width: 10),
                        _roundAction(
                          icon: Icons.store,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShopScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4D9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: Color(0xFFE2B71B),
                        size: 42,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You’re almost there!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2A1F1F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'XP to next step',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${1000 - (xp % 1000)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2A1F1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Lessons Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F2034),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$xp xp done',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Goal 1000',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _infoMiniCard(
                            title: 'Full Name',
                            value: _fullName.isNotEmpty ? _fullName : '—',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoMiniCard(
                            title: 'Nickname',
                            value: nickname.isNotEmpty ? nickname : '—',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _infoMiniCard(
                            title: 'Level',
                            value: level.isNotEmpty ? level : 'A0',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoMiniCard(
                            title: 'XP',
                            value: '$xp',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: savingNick ? null : _openChangeNickname,
                  icon: savingNick
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.edit_outlined),
                  label: const Text(
                    'Nickname өзгерту',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'More',
                  style: TextStyle(
                    color: Color(0xFF434343),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _moreTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help with your account and app usage',
                onTap: () => _errorSnack('Help & Support кейін қосамыз'),
              ),
              const SizedBox(height: 10),
              _moreTile(
                icon: Icons.favorite_border,
                title: 'About App',
                subtitle: 'Learn more about OYU',
                onTap: () => _errorSnack('About App кейін қосамыз'),
              ),
              const SizedBox(height: 10),
              _moreTile(
                icon: Icons.logout,
                title: 'Log out',
                subtitle: 'Further secure your account for safety',
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill({required String text, required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? purple : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: filled ? purple : const Color(0xFF222222),
          width: 1.1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? Colors.white : const Color(0xFF222222),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _topStat({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2A2A2A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF4EEFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: purple),
      ),
    );
  }

  Widget _infoMiniCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black45)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF242424),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF4EEFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, color: purple, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class InviteSearchSheet extends StatefulWidget {
  final int myUserId;
  final String myNickname;
  final String myUsername;
  final FollowService followService;

  const InviteSearchSheet({
    super.key,
    required this.myUserId,
    required this.myNickname,
    required this.myUsername,
    required this.followService,
  });

  @override
  State<InviteSearchSheet> createState() => _InviteSearchSheetState();
}

class _InviteSearchSheetState extends State<InviteSearchSheet> {
  static const Color purple = Color(0xFF8E5BFF);

  final TextEditingController _searchC = TextEditingController();

  bool searching = false;
  bool actionLoading = false;
  String? error;
  SearchUserResult? foundUser;
  bool? isFollowing;

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final nick = _searchC.text.trim();
    if (nick.isEmpty) {
      setState(() {
        error = 'Nickname енгіз';
        foundUser = null;
        isFollowing = null;
      });
      return;
    }

    setState(() {
      searching = true;
      error = null;
      foundUser = null;
      isFollowing = null;
    });

    try {
      final user = await widget.followService.findByNickname(nick);

      if (user == null) {
        setState(() {
          error = 'User табылмады';
          searching = false;
        });
        return;
      }

      bool? followStatus;
      if (user.id != widget.myUserId) {
        followStatus = await widget.followService.isFollowing(user.id);
      }

      setState(() {
        foundUser = user;
        isFollowing = followStatus;
        searching = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        searching = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final user = foundUser;
    if (user == null) return;
    if (user.id == widget.myUserId) return;

    setState(() => actionLoading = true);

    try {
      if (isFollowing == true) {
        await widget.followService.unfollow(user.id);
      } else {
        await widget.followService.follow(user.id);
      }

      final status = await widget.followService.isFollowing(user.id);

      setState(() {
        isFollowing = status;
        actionLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status ? 'Follow жасалды' : 'Unfollow жасалды',
          ),
        ),
      );
    } catch (e) {
      setState(() => actionLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Invite by nickname',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF232323),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchC,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'john_123',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: const Color(0xFFF6F2FF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: searching ? null : _search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: searching
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Search',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (foundUser != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: purple.withOpacity(0.14),
                          child: Text(
                            (foundUser!.nickname.isNotEmpty
                                ? foundUser!.nickname
                                : foundUser!.username)
                                .characters
                                .first
                                .toUpperCase(),
                            style: const TextStyle(
                              color: purple,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                foundUser!.nickname.isNotEmpty
                                    ? foundUser!.nickname
                                    : foundUser!.username,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                foundUser!.username,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Level ${foundUser!.level} • XP ${foundUser!.xp}',
                                style: const TextStyle(
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (foundUser!.id == widget.myUserId)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF8EF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Бұл өзіңнің аккаунтың',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: actionLoading ? null : _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isFollowing == true ? Colors.white : purple,
                          foregroundColor:
                          isFollowing == true ? const Color(0xFF232323) : Colors.white,
                          elevation: 0,
                          side: isFollowing == true
                              ? const BorderSide(color: Colors.black12)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: actionLoading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: isFollowing == true
                                ? const Color(0xFF232323)
                                : Colors.white,
                          ),
                        )
                            : Text(
                          isFollowing == true ? 'Unfollow' : 'Follow',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BioDataScreen extends StatefulWidget {
  final String fullName;
  final String nickname;
  final String level;
  final String email;
  final Future<void> Function(String value) onSaveName;
  final Future<void> Function(String value) onSaveNickname;

  const BioDataScreen({
    super.key,
    required this.fullName,
    required this.nickname,
    required this.level,
    required this.email,
    required this.onSaveName,
    required this.onSaveNickname,
  });

  @override
  State<BioDataScreen> createState() => _BioDataScreenState();
}

class _BioDataScreenState extends State<BioDataScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  late final TextEditingController _nameC;
  late final TextEditingController _nickC;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.fullName);
    _nickC = TextEditingController(text: widget.nickname);
  }

  @override
  void dispose() {
    _nameC.dispose();
    _nickC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = _nameC.text.trim();
    final newNick = _nickC.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name бос болмауы керек')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await widget.onSaveName(newName);

      if (newNick.isNotEmpty && newNick != widget.nickname) {
        await widget.onSaveNickname(newNick);
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black45),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black12),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: purple, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
    widget.nickname.isNotEmpty ? widget.nickname : widget.fullName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Text(
                    'Bio-data',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 46,
              backgroundColor: const Color(0xFFE9E4FF),
              child: Text(
                initial,
                style: const TextStyle(
                  color: purple,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email.isNotEmpty ? widget.email : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black38,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 44),
            TextField(
              controller: _nameC,
              decoration: _input('Name'),
            ),
            const SizedBox(height: 24),
            TextField(
              readOnly: true,
              decoration: _input('Email'),
              controller: TextEditingController(
                text: widget.email.isNotEmpty ? widget.email : '—',
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nickC,
              decoration: _input('Nickname'),
            ),
            const SizedBox(height: 24),
            TextField(
              readOnly: true,
              decoration: _input('Level'),
              controller: TextEditingController(text: widget.level),
            ),
            const SizedBox(height: 44),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C0399),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Update Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FollowersListScreen extends StatelessWidget {
  final int userId;
  const FollowersListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return _FollowListBase(
      title: 'Followers',
      loadPage: (cursor) => FollowService().getFollowers(userId: userId, cursor: cursor),
    );
  }
}

class FollowingListScreen extends StatelessWidget {
  final int userId;
  const FollowingListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return _FollowListBase(
      title: 'Following',
      loadPage: (cursor) => FollowService().getFollowing(userId: userId, cursor: cursor),
    );
  }
}

typedef _LoadPage = Future<FollowPage> Function(int? cursor);

class _FollowListBase extends StatefulWidget {
  final String title;
  final _LoadPage loadPage;

  const _FollowListBase({
    required this.title,
    required this.loadPage,
  });

  @override
  State<_FollowListBase> createState() => _FollowListBaseState();
}

class _FollowListBaseState extends State<_FollowListBase> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  bool loading = true;
  bool loadingMore = false;
  String? error;

  int? cursor;
  bool hasMore = true;
  final List<FollowUser> items = [];

  void _errorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    _load(first: true);
  }

  Future<void> _load({required bool first}) async {
    setState(() {
      if (first) {
        loading = true;
        error = null;
        cursor = null;
        hasMore = true;
        items.clear();
      } else {
        loadingMore = true;
      }
    });

    try {
      final page = await widget.loadPage(first ? null : cursor);
      if (!mounted) return;

      setState(() {
        items.addAll(page.items);
        cursor = page.nextCursor;
        hasMore = page.nextCursor != null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
      _errorSnack(e.toString());
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: purple,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Text(
          error!,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == items.length) {
            return SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: loadingMore ? null : () => _load(first: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loadingMore
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text(
                  'Load more',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }

          final u = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => PublicUserProfileScreen(userId: u.id),
                ),
              );
            },
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
                    backgroundColor: const Color(0xFFE9DFFF),
                    child: Text(
                      u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
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
                          u.nickname.isNotEmpty ? u.nickname : u.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Level ${u.level} • XP ${u.xp}',
                          style: const TextStyle(color: Colors.black54),
                        ),
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
}

class PublicUserProfileScreen extends StatefulWidget {
  final int userId;
  const PublicUserProfileScreen({super.key, required this.userId});

  @override
  State<PublicUserProfileScreen> createState() => _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  final _follow = FollowService();
  final _auth = AuthService();

  bool loading = true;
  bool actionLoading = false;
  bool isFollowing = false;
  FollowCounts? counts;
  int? myId;

  void _errorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      myId = await _auth.getUserId();
      final c = await _follow.getCounts(widget.userId);
      final f =
      (myId != null && myId != widget.userId) ? await _follow.isFollowing(widget.userId) : false;

      if (!mounted) return;
      setState(() {
        counts = c;
        isFollowing = f;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _errorSnack(e.toString());
    }
  }

  Future<void> _toggleFollow() async {
    if (myId == null || myId == widget.userId) return;

    setState(() => actionLoading = true);
    try {
      if (isFollowing) {
        await _follow.unfollow(widget.userId);
      } else {
        await _follow.follow(widget.userId);
      }

      final c = await _follow.getCounts(widget.userId);
      final f = await _follow.isFollowing(widget.userId);

      if (!mounted) return;
      setState(() {
        counts = c;
        isFollowing = f;
        actionLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => actionLoading = false);
      _errorSnack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final canFollow = myId != null && myId != widget.userId;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: purple,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${widget.userId}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PublicStat(
                        label: 'Following',
                        value: '${counts?.followingCount ?? 0}',
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.black12),
                    Expanded(
                      child: _PublicStat(
                        label: 'Followers',
                        value: '${counts?.followersCount ?? 0}',
                      ),
                    ),
                  ],
                ),
                if (canFollow) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: actionLoading ? null : _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: actionLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(
                        isFollowing ? 'Unfollow' : 'Follow',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicStat extends StatelessWidget {
  final String label;
  final String value;

  const _PublicStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}