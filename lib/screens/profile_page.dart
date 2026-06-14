import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/screens/shop_screen.dart';
import 'package:kazakh_learning_app/screens/dictionary_screen.dart';
import 'package:kazakh_learning_app/screens/friends_screen.dart';
import 'package:kazakh_learning_app/services/friend_service.dart';
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
  bool _xpStatsLoading = true;
  bool _leaderboardLoading = true;
  String? error;

  String nickname = '';
  String email = '';
  int xp = 0;
  String level = '';
  int userId = 0;

  late String _fullName;

  final FollowService _follow = FollowService();
  final FriendService _friendService = FriendService();
  FollowCounts? _counts;
  bool _countsLoading = true;
  int _friendsCount = 0;
  int _incomingFriendRequests = 0;
  String _xpWindow = 'WEEKLY';
  int _dailyXp = 0;
  int _weeklyXp = 0;
  int _allTimeXp = 0;
  int _bestDayXp = 0;
  int _bestWeekXp = 0;
  int _averagePerActiveDay = 0;
  String _leaderboardWindow = 'week';
  List<Map<String, dynamic>> _leaderboardItems = [];

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
      _xpStatsLoading = true;
      _leaderboardLoading = true;
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

      int friendsCount = 0;
      int incomingFriendRequests = 0;
      if (uid > 0) {
        try {
          final friends = await _friendService.getFriends();
          friendsCount = friends.length;
        } catch (_) {}
        try {
          final incomingRequests = await _friendService.getIncomingRequests();
          incomingFriendRequests = incomingRequests.length;
        } catch (_) {}
      }

      await _loadXpStats();
      await _loadLeaderboard();

      final resolvedXp =
          (me['xp'] ?? 0) is int ? (me['xp'] ?? 0) : int.tryParse('${me['xp']}') ?? 0;

      setState(() {
        nickname = finalNick;
        email = (me['email'] ?? me['user']?['email'] ?? '').toString().trim();
        xp = resolvedXp;
        if (_dailyXp == 0 && resolvedXp > 0) {
          _dailyXp = resolvedXp;
        }
        if (_weeklyXp == 0 && resolvedXp > 0) {
          _weeklyXp = resolvedXp;
        }
        if (_allTimeXp < resolvedXp) {
          _allTimeXp = resolvedXp;
        }
        if (_xpWindow == 'ALL_TIME' && _averagePerActiveDay == 0 && resolvedXp > 0) {
          _averagePerActiveDay = resolvedXp;
        }
        level = (me['level'] ?? 'A0').toString();
        _counts = c;
        _friendsCount = friendsCount;
        _incomingFriendRequests = incomingFriendRequests;
        loading = false;
        _countsLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'ME error: $e';
        loading = false;
        _countsLoading = false;
        _xpStatsLoading = false;
        _leaderboardLoading = false;
      });
    }
  }

  Future<void> _loadXpStats() async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => _xpStatsLoading = false);
      }
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/progress/xp-stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode != 200) {
        if (mounted) {
          setState(() => _xpStatsLoading = false);
        }
        return;
      }

      final decoded = _safeJsonMap(res.body);
      if (!mounted) return;

      int toInt(dynamic value) {
        if (value is int) return value;
        return int.tryParse('$value') ?? 0;
      }

      setState(() {
        _dailyXp = toInt(decoded['dailyXp']);
        _weeklyXp = toInt(decoded['weeklyXp']);
        _allTimeXp = toInt(decoded['allTimeXp']);
        _bestDayXp = toInt(decoded['bestDayXp']);
        _bestWeekXp = toInt(decoded['bestWeekXp']);
        _averagePerActiveDay = toInt(decoded['averagePerActiveDay']);
        _xpStatsLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _xpStatsLoading = false);
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final token = await AuthService().getToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() => _leaderboardLoading = false);
        }
        return;
      }

      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/leaderboard?limit=50&period=$_leaderboardWindow'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode != 200) {
        if (mounted) {
          setState(() => _leaderboardLoading = false);
        }
        return;
      }

      final decoded = jsonDecode(res.body);
      if (!mounted) return;

      if (decoded is List) {
        final periodItems = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final allTimeRes = await http.get(
          Uri.parse('${AuthService.baseUrl}/leaderboard?limit=50&period=all'),
          headers: {'Authorization': 'Bearer $token'},
        );

        List<Map<String, dynamic>> allTimeItems = [];
        if (allTimeRes.statusCode == 200) {
          final allTimeDecoded = jsonDecode(allTimeRes.body);
          if (allTimeDecoded is List) {
            allTimeItems = allTimeDecoded
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }

        final topThree = <Map<String, dynamic>>[];
        for (final item in periodItems) {
          if (topThree.length == 3) break;
          topThree.add(item);
        }
        for (final item in allTimeItems) {
          if (topThree.length == 3) break;
          final exists = topThree.any((row) => '${row['id']}' == '${item['id']}');
          if (!exists) {
            topThree.add({
              ...item,
              'periodXp': 0,
            });
          }
        }

        final currentUser = periodItems.cast<Map<String, dynamic>?>().firstWhere(
              (item) {
                final rowUserId = item?['id'] is int
                    ? item!['id'] as int
                    : int.tryParse('${item?['id']}') ?? 0;
                return rowUserId == userId;
              },
              orElse: () => null,
            );

        final fallbackCurrentUser = currentUser ??
            allTimeItems.cast<Map<String, dynamic>?>().firstWhere(
              (item) {
                final rowUserId = item?['id'] is int
                    ? item!['id'] as int
                    : int.tryParse('${item?['id']}') ?? 0;
                return rowUserId == userId;
              },
              orElse: () => null,
            );

        final displayItems = <Map<String, dynamic>>[...topThree];
        if (fallbackCurrentUser != null &&
            !displayItems.any((item) => '${item['id']}' == '${fallbackCurrentUser['id']}')) {
          displayItems.add({
            ...fallbackCurrentUser,
            'periodXp': currentUser?['periodXp'] ?? 0,
          });
        }

        final normalizedItems = displayItems.map((item) {
          final totalXp = item['xp'] is int ? item['xp'] as int : int.tryParse('${item['xp']}') ?? 0;
          final rawPeriodXp = item['periodXp'] is int
              ? item['periodXp'] as int
              : int.tryParse('${item['periodXp']}') ?? 0;
          return {
            ...item,
            'periodXp': rawPeriodXp > totalXp ? totalXp : rawPeriodXp,
          };
        }).toList();

        if (_leaderboardWindow == 'week' || _leaderboardWindow == 'month') {
          normalizedItems.sort((a, b) {
            final aPoints = a['periodXp'] is int ? a['periodXp'] as int : int.tryParse('${a['periodXp']}') ?? 0;
            final bPoints = b['periodXp'] is int ? b['periodXp'] as int : int.tryParse('${b['periodXp']}') ?? 0;
            if (bPoints != aPoints) return bPoints - aPoints;
            final aRank = a['rank'] is int ? a['rank'] as int : int.tryParse('${a['rank']}') ?? 9999;
            final bRank = b['rank'] is int ? b['rank'] as int : int.tryParse('${b['rank']}') ?? 9999;
            return aRank - bRank;
          });
        }

        setState(() {
          _leaderboardItems = normalizedItems;
          _leaderboardLoading = false;
        });
        return;
      }

      setState(() => _leaderboardLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() => _leaderboardLoading = false);
      }
    }
  }

  String get _xpPrimaryLabel {
    switch (_xpWindow) {
      case 'DAILY':
        return 'Today';
      case 'ALL_TIME':
        return 'Total';
      default:
        return 'This week';
    }
  }

  int get _xpPrimaryValue {
    switch (_xpWindow) {
      case 'DAILY':
        return _dailyXp;
      case 'ALL_TIME':
        return _allTimeXp > 0 ? _allTimeXp : xp;
      default:
        return _weeklyXp;
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
    final friendsCount = _countsLoading ? '—' : '$_friendsCount';
    final requestsCount = _countsLoading ? '—' : '$_incomingFriendRequests';
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
                            title: 'Friends',
                            value: friendsCount,
                            onTap: () async {
                              await Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => const FriendsScreen(),
                                ),
                              );

                              if (mounted) {
                                await _loadMe();
                              }
                            },
                          ),
                        ),
                        Container(width: 1, height: 34, color: Colors.black12),
                        Expanded(
                          child: _topStat(
                            title: 'Requests',
                            value: requestsCount,
                            onTap: () async {
                              await Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => const FriendsScreen(),
                                ),
                              );

                              if (mounted) {
                                await _loadMe();
                              }
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FriendsScreen(),
                                ),
                              ).then((_) => _loadMe());
                            },
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
                                  'FRIENDS',
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
                        const SizedBox(width: 10),
                        _roundAction(
                          icon: Icons.menu_book_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DictionaryScreen(),
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
                            "You're almost there!",
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
                      'Your XP Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F2034),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFEA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _xpSwitchChip(label: 'Daily', value: 'DAILY')),
                          Expanded(child: _xpSwitchChip(label: 'Weekly', value: 'WEEKLY')),
                          Expanded(
                            child: _xpSwitchChip(label: 'All time', value: 'ALL_TIME'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_xpStatsLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(color: purple),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _xpPrimaryLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF928688),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$_xpPrimaryValue',
                                style: const TextStyle(
                                  fontSize: 42,
                                  height: 1,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text(
                                  'XP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFB4A9AA),
                                  ),
                                ),
                              ),
                            ],
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
                    Row(
                      children: [
                        const Icon(Icons.public_rounded, color: purple),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'World Records',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2F2034),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFEA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _leaderboardSwitchChip(
                              label: 'Week',
                              value: 'week',
                            ),
                          ),
                          Expanded(
                            child: _leaderboardSwitchChip(
                              label: 'Month',
                              value: 'month',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_leaderboardLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: CircularProgressIndicator(color: purple),
                        ),
                      )
                    else if (_leaderboardItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'No leaderboard data yet',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F4FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE4CEF9)),
                        ),
                        child: Column(
                          children: List.generate(_leaderboardItems.length, (index) {
                            final item = _leaderboardItems[index];
                            final rowUserId = item['id'] is int
                                ? item['id'] as int
                                : int.tryParse('${item['id']}') ?? 0;
                            final isCurrentUser = rowUserId == userId;
                            final displayName =
                                (item['username'] ?? 'User').toString().trim();
                            final points = item['periodXp'] ?? item['xp'] ?? 0;
                            final rank = item['rank'] ?? (index + 1);
                            final medal = index == 0
                                ? const Color(0xFFFFB800)
                                : index == 1
                                    ? const Color(0xFFB7BEC8)
                                    : index == 2
                                        ? const Color(0xFFC76A00)
                                        : const Color(0xFF8E5BFF);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? const Color(0xFFF0E5FF)
                                    : Colors.transparent,
                                border: index == _leaderboardItems.length - 1
                                    ? null
                                    : const Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFEADCF6),
                                        ),
                                      ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: index < 3
                                        ? Icon(
                                            Icons.workspace_premium_outlined,
                                            color: medal,
                                            size: 24,
                                          )
                                        : Text(
                                            '#$rank',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF4A4150),
                                            ),
                                          ),
                                  ),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8D8FF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Center(
                                      child: Text(
                                        displayName.isNotEmpty
                                            ? displayName.substring(0, 1).toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: purple,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isCurrentUser ? 'You ($displayName)' : displayName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2F2034),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (item['level'] ?? 'KZ').toString(),
                                          style: const TextStyle(
                                            color: Color(0xFF7A7091),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$points',
                                        style: const TextStyle(
                                          color: purple,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Text(
                                        'points',
                                        style: TextStyle(
                                          color: Color(0xFF7A7091),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
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

  Widget _xpSwitchChip({
    required String label,
    required String value,
  }) {
    final selected = _xpWindow == value;

    return InkWell(
      onTap: () => setState(() => _xpWindow = value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF1D1D1D) : const Color(0xFF5F5758),
          ),
        ),
      ),
    );
  }

  Widget _leaderboardSwitchChip({
    required String label,
    required String value,
  }) {
    final selected = _leaderboardWindow == value;

    return InkWell(
      onTap: () {
        if (_leaderboardWindow == value) return;
        setState(() {
          _leaderboardWindow = value;
          _leaderboardLoading = true;
        });
        _loadLeaderboard();
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF1D1D1D) : const Color(0xFF5F5758),
          ),
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

  String _clean(String? value) => (value ?? '').trim();

  String _displayName(SearchUserResult user) {
    final nick = _clean(user.nickname);
    final username = _clean(user.username);

    if (nick.isNotEmpty) return nick;
    if (username.isNotEmpty) return username;
    return 'Unknown user';
  }

  String _secondLine(SearchUserResult user) {
    final username = _clean(user.username);
    final nickname = _clean(user.nickname);

    if (username.isNotEmpty) return '@$username';
    if (nickname.isNotEmpty) return '@$nickname';
    return 'ID: ${user.id}';
  }

  String _initial(SearchUserResult user) {
    final name = _displayName(user).trim();
    if (name.isEmpty || name == 'Unknown user') return '?';
    return name.characters.first.toUpperCase();
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

      if (!mounted) return;

      if (user == null) {
        setState(() {
          error = 'User табылмады';
          searching = false;
        });
        return;
      }

      if (user.id <= 0) {
        setState(() {
          error = 'Backend user id жібермеді';
          foundUser = null;
          isFollowing = null;
          searching = false;
        });
        return;
      }

      bool followStatus = false;
      if (user.id != widget.myUserId) {
        try {
          followStatus = await widget.followService.isFollowing(user.id);
        } catch (e) {
          debugPrint('isFollowing error: $e');
          followStatus = false;
        }
      }

      if (!mounted) return;

      setState(() {
        foundUser = user;
        isFollowing = followStatus;
        searching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        foundUser = null;
        isFollowing = null;
        searching = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final user = foundUser;
    if (user == null) return;
    if (user.id == widget.myUserId) return;

    if (user.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User id табылмады')),
      );
      return;
    }

    final nextStatus = isFollowing != true;

    setState(() => actionLoading = true);

    try {
      if (isFollowing == true) {
        await widget.followService.unfollow(user.id);
      } else {
        await widget.followService.follow(user.id);
      }

      bool status = nextStatus;
      try {
        status = await widget.followService.isFollowing(user.id);
      } catch (e) {
        debugPrint('isFollowing after follow error: $e');
      }

      if (!mounted) return;

      setState(() {
        isFollowing = status;
        actionLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status ? 'Follow жасалды' : 'Unfollow жасалды'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => actionLoading = false);

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
                  Builder(
                    builder: (_) {
                      final user = foundUser!;
                      final displayName = _displayName(user);
                      final secondLine = _secondLine(user);

                      return Container(
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
                                _initial(user),
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
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    secondLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Level ${user.level} • XP ${user.xp}',
                                    style: const TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                          foregroundColor: isFollowing == true
                              ? const Color(0xFF232323)
                              : Colors.white,
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
          final displayName = u.nickname.isNotEmpty
              ? u.nickname
              : (u.username.isNotEmpty ? u.username : 'User ${u.id}');
          final initial = displayName.characters.first.toUpperCase();

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              await Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => PublicUserProfileScreen(userId: u.id),
                ),
              );

              if (mounted) {
                await _load(first: true);
              }
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
                      initial,
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
                          displayName,
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






