import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/services/friend_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  final FriendService _friendService = FriendService();
  final TextEditingController _searchC = TextEditingController();

  bool _loading = true;
  bool _actionLoading = false;
  FriendUser? _searchedUser;
  String _searchedStatus = 'NONE';
  List<FriendRequestItem> _incoming = [];
  List<FriendListItem> _friends = [];
  List<FriendUser> _suggestions = [];
  String? _error;
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _myUserId = await AuthService().getUserId();
      final incoming = await _friendService.getIncomingRequests();
      final friends = await _friendService.getFriends();
      final suggestions = await _friendService.getSuggestions();
      if (!mounted) return;
      setState(() {
        _incoming = incoming;
        _friends = friends;
        _suggestions = suggestions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _search() async {
    final nickname = _searchC.text.trim();
    if (nickname.isEmpty) return;

    setState(() {
      _actionLoading = true;
      _searchedUser = null;
      _searchedStatus = 'NONE';
    });

    try {
      final user = await _friendService.findByNickname(nickname);
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _searchedUser = null;
          _searchedStatus = 'NONE';
          _actionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      final status = user.id == _myUserId
          ? 'SELF'
          : await _friendService.getFriendStatus(user.id);
      if (!mounted) return;
      setState(() {
        _searchedUser = user;
        _searchedStatus = status;
        _actionLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _sendRequestForUser(FriendUser user) async {
    setState(() => _actionLoading = true);
    try {
      await _friendService.sendFriendRequest(user.id);
      if (!mounted) return;
      setState(() {
        if (_searchedUser?.id == user.id) {
          _searchedStatus = 'OUTGOING_REQUEST';
        }
        _suggestions =
            _suggestions.where((item) => item.id != user.id).toList();
        _actionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent')),
      );
      await _init();
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _sendRequest() async {
    final user = _searchedUser;
    if (user == null) return;
    await _sendRequestForUser(user);
  }

  Future<void> _accept(FriendRequestItem item) async {
    setState(() => _actionLoading = true);
    try {
      await _friendService.acceptFriendRequest(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted')),
      );
      await _init();
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _decline(FriendRequestItem item) async {
    setState(() => _actionLoading = true);
    try {
      await _friendService.declineFriendRequest(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request declined')),
      );
      await _init();
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _removeFriend(FriendListItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove friend?'),
        content: Text('Remove ${item.user.displayName} from friends?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: purple),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _actionLoading = true);
    try {
      await _friendService.removeFriend(item.user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend removed')),
      );
      await _init();
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _openFriendProfile(FriendUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FriendProfileScreen(userId: user.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('Friends',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: purple,
              onRefresh: _init,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Find by nickname',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchC,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _search(),
                                decoration: InputDecoration(
                                  hintText: 'nickname',
                                  filled: true,
                                  fillColor: const Color(0xFFF6F2FF),
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _actionLoading ? null : _search,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _actionLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white),
                                      )
                                    : const Text('Search'),
                              ),
                            ),
                          ],
                        ),
                        if (_searchedUser != null) ...[
                          const SizedBox(height: 14),
                          _FriendCard(
                            user: _searchedUser!,
                            subtitle:
                                'Level ${_searchedUser!.level} � XP ${_searchedUser!.xp}',
                            trailing: _buildSearchAction(),
                            onTap: () => _openFriendProfile(_searchedUser!),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                      title: 'Incoming requests', count: _incoming.length),
                  const SizedBox(height: 10),
                  if (_incoming.isEmpty)
                    const _EmptyBox(text: 'No incoming requests')
                  else
                    ..._incoming.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FriendCard(
                          user: item.user,
                          subtitle:
                              'Level ${item.user.level} � XP ${item.user.xp}',
                          onTap: () => _openFriendProfile(item.user),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed:
                                    _actionLoading ? null : () => _accept(item),
                                icon: const Icon(Icons.check_circle_rounded,
                                    color: Colors.green),
                              ),
                              IconButton(
                                onPressed: _actionLoading
                                    ? null
                                    : () => _decline(item),
                                icon: const Icon(Icons.cancel_rounded,
                                    color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'Friends', count: _friends.length),
                  const SizedBox(height: 10),
                  if (_friends.isEmpty)
                    const _EmptyBox(text: 'No friends yet')
                  else
                    ..._friends.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FriendCard(
                          user: item.user,
                          subtitle:
                              'Level ${item.user.level} � XP ${item.user.xp}',
                          onTap: () => _openFriendProfile(item.user),
                          trailing: IconButton(
                            onPressed: _actionLoading
                                ? null
                                : () => _removeFriend(item),
                            icon: const Icon(Icons.person_remove_alt_1_rounded,
                                color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _SectionTitle(
                      title: 'People you may know', count: _suggestions.length),
                  const SizedBox(height: 10),
                  if (_suggestions.isEmpty)
                    const _EmptyBox(text: 'No recommendations right now')
                  else
                    ..._suggestions.map(
                      (user) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FriendCard(
                          user: user,
                          subtitle: 'Level ${user.level} � XP ${user.xp}',
                          onTap: () => _openFriendProfile(user),
                          trailing: ElevatedButton(
                            onPressed: _actionLoading
                                ? null
                                : () => _sendRequestForUser(user),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: purple),
                            child: const Text('Add',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchAction() {
    switch (_searchedStatus) {
      case 'SELF':
        return const Text('You', style: TextStyle(fontWeight: FontWeight.w800));
      case 'FRIENDS':
        return const Text('Friends',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green));
      case 'OUTGOING_REQUEST':
        return const Text('Requested',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: Colors.orange));
      case 'INCOMING_REQUEST':
        return const Text('Incoming',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blue));
      default:
        return ElevatedButton(
          onPressed: _actionLoading ? null : _sendRequest,
          style: ElevatedButton.styleFrom(backgroundColor: purple),
          child: const Text('Add friend',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        );
    }
  }
}

class FriendProfileScreen extends StatefulWidget {
  final int userId;

  const FriendProfileScreen({super.key, required this.userId});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  final FriendService _friendService = FriendService();
  bool _loading = true;
  String? _error;
  FriendProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _friendService.getFriendProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: purple,
        title: const Text('Friend profile'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(fontWeight: FontWeight.w800)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: const Color(0xFFE9DFFF),
                            child: Text(
                              _profile!.user.displayName.characters.first
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: purple,
                                fontWeight: FontWeight.w900,
                                fontSize: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _profile!.user.displayName,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${_profile!.user.username}',
                            style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 18),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.45,
                            children: [
                              _StatBox(
                                  title: 'XP', value: '${_profile!.user.xp}'),
                              _StatBox(
                                  title: 'Level', value: _profile!.user.level),
                              _StatBox(
                                  title: 'Friends',
                                  value: '${_profile!.friendsCount}'),
                              _StatBox(
                                  title: 'Top rank',
                                  value: _profile!.leaderboardRank > 0
                                      ? '#${_profile!.leaderboardRank}'
                                      : '�'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: const TextStyle(
              color: Colors.black45, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style:
            const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final FriendUser user;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _FriendCard({
    required this.user,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE9DFFF),
              child: Text(
                user.displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF8E5BFF),
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
                    user.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;

  const _StatBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black45)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF232323),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}
