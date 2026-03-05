import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/auth_service.dart';

class ModeratorUserDetailScreen extends StatefulWidget {
  final String userId;
  const ModeratorUserDetailScreen({super.key, required this.userId});

  @override
  State<ModeratorUserDetailScreen> createState() => _ModeratorUserDetailScreenState();
}

class _ModeratorUserDetailScreenState extends State<ModeratorUserDetailScreen> {
  static const purple = Color(0xFF8E5BFF);
  static const bg = Color(0xFFF6F1FF);

  bool loading = true;
  String? error;
  Map<String, dynamic> user = {};

  double _cardH = 0;

  Map<String, dynamic> _safeMap(String body) {
    try {
      final d = jsonDecode(body);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {};
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
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
        Uri.parse('${AuthService.baseUrl}/admin/users/${widget.userId}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        setState(() {
          user = _safeMap(res.body);
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
          title: const Text('User'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
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
                onPressed: _loadUser,
                child: const Text('Қайта жүктеу'),
              ),
            ],
          ),
        ),
      );
    }

    final username = (user['username'] ?? '—').toString();
    final email = (user['email'] ?? '—').toString();
    final role = (user['role'] ?? 'USER').toString().toUpperCase();
    final level = (user['level'] ?? 'A0').toString();
    final createdAt = (user['createdAt'] ?? '').toString();

    final following = 11;
    final followers = 9;
    final joined = createdAt.isNotEmpty ? _formatJoined(createdAt) : 'Joined —';

    const double headerH = 190;
    const double side = 16;
    const double cardTop = 118;
    const double gapAfterCard = 8;

    final double overlap = headerH - cardTop;
    final double cardH = (_cardH > 0) ? _cardH : 210;
    final double firstSliverH = headerH + max(0, cardH - overlap) + gapAfterCard;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: firstSliverH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Header
                    Container(
                      height: headerH,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: purple,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(26),
                          bottomRight: Radius.circular(26),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            // ✅ back button төмен түссін
                            padding: const EdgeInsets.only(top: 10, left: 6),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Overlapping Profile Card (measured)
                    Positioned(
                      top: cardTop,
                      left: side,
                      right: side,
                      child: _MeasureSize(
                        onChange: (s) {
                          if (!mounted) return;
                          if (s.height != _cardH) setState(() => _cardH = s.height);
                        },
                        child: _ProfileCard(
                          name: username,
                          subtitle: '$email • $joined',
                          role: role,
                          level: level,
                          following: following,
                          followers: followers,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
              sliver: SliverToBoxAdapter(
                child: _AchievementsGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJoined(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return 'Joined ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'Joined —';
    }
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  final void Function(Size size) onChange;

  const _MeasureSize({
    required this.onChange,
    required Widget child,
    super.key,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasureSize renderObject) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  void Function(Size size) onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize != null && _oldSize != newSize) {
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
    }
  }
}

// ===== UI widgets (unchanged) =====
class _ProfileCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String role;
  final String level;
  final int following;
  final int followers;

  const _ProfileCard({
    required this.name,
    required this.subtitle,
    required this.role,
    required this.level,
    required this.following,
    required this.followers,
  });

  static const purple = Color(0xFF8E5BFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFE9DFFF),
                    child: Icon(Icons.person, color: purple),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Color(0xFFA7F3D0),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ),
                        _RoleChip(role: role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _iconCircle(Icons.settings, () {}),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statBlock('Level', level)),
              _divider(),
              Expanded(child: _statBlock('Following', '$following')),
              _divider(),
              Expanded(child: _statBlock('Followers', '$followers')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: purple.withOpacity(0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('INVITE', style: TextStyle(color: purple, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: purple.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.ios_share, color: purple),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _divider() => Container(width: 1, height: 36, color: Colors.black12);

  static Widget _statBlock(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  static Widget _iconCircle(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: purple.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
        child: Icon(icon, color: purple),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  static const purple = Color(0xFF8E5BFF);

  @override
  Widget build(BuildContext context) {
    final text = role.isEmpty ? 'USER' : role;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: purple.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(color: purple, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  static const purple = Color(0xFF8E5BFF);

  const _AchievementsGrid();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _AchItem(icon: '🔥', title: 'Week Streak'),
      _AchItem(icon: '🌟', title: 'First Letter'),
      _AchItem(icon: '🏆', title: 'Quiz Master'),
      _AchItem(icon: '📚', title: 'Bookworm'),
      _AchItem(icon: '🎯', title: 'Sharp Shooter'),
      _AchItem(icon: '💎', title: 'Diamond League'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) {
        final it = items[i];
        final disabled = i >= 4;
        return Container(
          decoration: BoxDecoration(
            color: disabled ? Colors.white.withOpacity(0.60) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: purple.withOpacity(0.22)),
          ),
          child: Opacity(
            opacity: disabled ? 0.45 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(it.icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 10),
                Text(
                  it.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AchItem {
  final String icon;
  final String title;
  const _AchItem({required this.icon, required this.title});
}