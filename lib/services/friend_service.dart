import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/auth_service.dart';

class FriendUser {
  final int id;
  final String username;
  final String nickname;
  final String level;
  final int xp;

  const FriendUser({
    required this.id,
    required this.username,
    required this.nickname,
    required this.level,
    required this.xp,
  });

  String get displayName {
    if (nickname.trim().isNotEmpty) return nickname.trim();
    if (username.trim().isNotEmpty) return username.trim();
    return 'User $id';
  }

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse('$value') ?? 0;
    }

    String clean(dynamic value) {
      if (value == null) return '';
      final raw = value.toString().trim();
      return raw.toLowerCase() == 'null' ? '' : raw;
    }

    return FriendUser(
      id: toInt(json['id']),
      username: clean(json['username']),
      nickname: clean(json['nickname']),
      level: clean(json['level']).isEmpty ? 'A0' : clean(json['level']),
      xp: toInt(json['xp']),
    );
  }
}

class FriendRequestItem {
  final int id;
  final String status;
  final FriendUser user;

  const FriendRequestItem({
    required this.id,
    required this.status,
    required this.user,
  });

  factory FriendRequestItem.fromIncoming(Map<String, dynamic> json) {
    return FriendRequestItem(
      id: int.tryParse('${json['id']}') ?? 0,
      status: (json['status'] ?? '').toString(),
      user: FriendUser.fromJson(Map<String, dynamic>.from(json['sender'] ?? {})),
    );
  }

  factory FriendRequestItem.fromOutgoing(Map<String, dynamic> json) {
    return FriendRequestItem(
      id: int.tryParse('${json['id']}') ?? 0,
      status: (json['status'] ?? '').toString(),
      user: FriendUser.fromJson(Map<String, dynamic>.from(json['receiver'] ?? {})),
    );
  }
}

class FriendListItem {
  final int friendshipId;
  final FriendUser user;

  const FriendListItem({
    required this.friendshipId,
    required this.user,
  });

  factory FriendListItem.fromJson(Map<String, dynamic> json) {
    return FriendListItem(
      friendshipId: int.tryParse('${json['friendshipId']}') ?? 0,
      user: FriendUser.fromJson(Map<String, dynamic>.from(json['user'] ?? {})),
    );
  }
}

class FriendProfile {
  final FriendUser user;
  final int friendsCount;
  final int leaderboardRank;

  const FriendProfile({
    required this.user,
    required this.friendsCount,
    required this.leaderboardRank,
  });

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse('$value') ?? 0;
    }

    return FriendProfile(
      user: FriendUser.fromJson(Map<String, dynamic>.from(json['user'] ?? {})),
      friendsCount: toInt(json['friendsCount']),
      leaderboardRank: toInt(json['leaderboardRank']),
    );
  }
}

class FriendService {
  Future<String> _token() async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token missing');
    }
    return token;
  }

  Map<String, dynamic> _safeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    final token = await _token();
    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _safeMap(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    throw Exception((data['message'] ?? 'Request failed (${res.statusCode})').toString());
  }

  Future<void> _send(String method, String url) async {
    final token = await _token();
    late http.Response res;

    if (method == 'POST') {
      res = await http.post(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    } else if (method == 'PATCH') {
      res = await http.patch(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    } else if (method == 'DELETE') {
      res = await http.delete(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    } else {
      throw Exception('Unsupported method');
    }

    final data = _safeMap(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }

    throw Exception((data['message'] ?? 'Request failed (${res.statusCode})').toString());
  }

  Future<FriendUser?> findByNickname(String nickname) async {
    final token = await _token();
    final safeNickname = nickname.trim();
    if (safeNickname.isEmpty) return null;

    final uri = Uri.parse('${AuthService.baseUrl}/user/search').replace(
      queryParameters: {'nickname': safeNickname},
    );

    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode == 404) return null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      dynamic rawUser;

      if (decoded is List) {
        if (decoded.isEmpty) return null;
        rawUser = decoded.first;
      } else if (decoded is Map) {
        rawUser = decoded['user'] ?? decoded['data'] ?? decoded['items'] ?? decoded['results'] ?? decoded;
        if (rawUser is List) {
          if (rawUser.isEmpty) return null;
          rawUser = rawUser.first;
        }
      }

      if (rawUser is! Map) return null;
      return FriendUser.fromJson(Map<String, dynamic>.from(rawUser));
    }

    final data = _safeMap(res.body);
    throw Exception((data['message'] ?? 'User search failed (${res.statusCode})').toString());
  }

  Future<String> getFriendStatus(int userId) async {
    final data = await _getJson('${AuthService.baseUrl}/user/$userId/friend-status');
    return (data['status'] ?? 'NONE').toString();
  }

  Future<void> sendFriendRequest(int userId) async {
    await _send('POST', '${AuthService.baseUrl}/user/$userId/friend-request');
  }

  Future<void> acceptFriendRequest(int requestId) async {
    await _send('PATCH', '${AuthService.baseUrl}/user/friend-requests/$requestId/accept');
  }

  Future<void> declineFriendRequest(int requestId) async {
    await _send('PATCH', '${AuthService.baseUrl}/user/friend-requests/$requestId/decline');
  }

  Future<void> removeFriend(int userId) async {
    await _send('DELETE', '${AuthService.baseUrl}/user/friends/$userId');
  }

  Future<List<FriendRequestItem>> getIncomingRequests() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('${AuthService.baseUrl}/user/friend-requests/incoming'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = _safeMap(res.body);
      throw Exception((data['message'] ?? 'Incoming requests failed (${res.statusCode})').toString());
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return <FriendRequestItem>[];
    return decoded
        .whereType<Map>()
        .map((e) => FriendRequestItem.fromIncoming(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<FriendRequestItem>> getOutgoingRequests() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('${AuthService.baseUrl}/user/friend-requests/outgoing'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = _safeMap(res.body);
      throw Exception((data['message'] ?? 'Outgoing requests failed (${res.statusCode})').toString());
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return <FriendRequestItem>[];
    return decoded
        .whereType<Map>()
        .map((e) => FriendRequestItem.fromOutgoing(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<FriendListItem>> getFriends() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('${AuthService.baseUrl}/user/friends'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = _safeMap(res.body);
      throw Exception((data['message'] ?? 'Friends load failed (${res.statusCode})').toString());
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return <FriendListItem>[];
    return decoded
        .whereType<Map>()
        .map((e) => FriendListItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<FriendUser>> getSuggestions({int limit = 8}) async {
    final token = await _token();
    final uri = Uri.parse('${AuthService.baseUrl}/user/friend-suggestions').replace(
      queryParameters: {'limit': '$limit'},
    );
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = _safeMap(res.body);
      throw Exception((data['message'] ?? 'Suggestions load failed (${res.statusCode})').toString());
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) return <FriendUser>[];
    return decoded
        .whereType<Map>()
        .map((e) => FriendUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<FriendProfile> getFriendProfile(int userId) async {
    final data = await _getJson('${AuthService.baseUrl}/user/$userId/friend-profile');
    return FriendProfile.fromJson(data);
  }
}


