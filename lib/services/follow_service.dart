import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/auth_service.dart';

class FollowCounts {
  final int followersCount;
  final int followingCount;

  FollowCounts({
    required this.followersCount,
    required this.followingCount,
  });

  factory FollowCounts.fromJson(Map<String, dynamic> json) {
    return FollowCounts(
      followersCount: _toInt(
        json['followersCount'] ?? json['followers'] ?? json['followers_count'],
      ),
      followingCount: _toInt(
        json['followingCount'] ?? json['following'] ?? json['following_count'],
      ),
    );
  }
}

class FollowUser {
  final int id;
  final String username;
  final String nickname;
  final String level;
  final int xp;

  FollowUser({
    required this.id,
    required this.username,
    required this.nickname,
    required this.level,
    required this.xp,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    final nested = json['following'] ??
        json['followed'] ??
        json['follower'] ??
        json['user'] ??
        json['profile'] ??
        json['member'] ??
        json['account'] ??
        json['data'] ??
        json;

    final data = nested is Map
        ? Map<String, dynamic>.from(nested)
        : Map<String, dynamic>.from(json);

    final merged = Map<String, dynamic>.from(json)..addAll(data);

    return FollowUser(
      id: _readUserId(merged),
      username: (merged['username'] ?? '').toString().trim(),
      nickname: (merged['nickname'] ?? '').toString().trim(),
      level: (merged['level'] ?? 'A0').toString().trim(),
      xp: _toInt(merged['xp']),
    );
  }
}

class FollowPage {
  final List<FollowUser> items;
  final int? nextCursor;

  FollowPage({
    required this.items,
    required this.nextCursor,
  });
}

class SearchUserResult {
  final int id;
  final String username;
  final String nickname;
  final String level;
  final int xp;
  final String email;

  SearchUserResult({
    required this.id,
    required this.username,
    required this.nickname,
    required this.level,
    required this.xp,
    required this.email,
  });

  factory SearchUserResult.fromJson(Map<String, dynamic> json) {
    return SearchUserResult(
      id: _readUserId(json),
      username: (json['username'] ?? '').toString().trim(),
      nickname: (json['nickname'] ?? '').toString().trim(),
      level: (json['level'] ?? 'A0').toString().trim(),
      xp: _toInt(json['xp']),
      email: (json['email'] ?? '').toString().trim(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? 0}') ?? 0;
}

int _readUserId(Map<String, dynamic> json) {
  const keys = [
    'id',
    'userId',
    'user_id',
    'targetUserId',
    'target_user_id',
    'followedUserId',
    'followed_user_id',
    'profileId',
    'profile_id',
    'memberId',
    'member_id',
    'accountId',
    'account_id',
  ];

  for (final key in keys) {
    final value = _toInt(json[key]);
    if (value > 0) return value;
  }

  const nestedKeys = ['user', 'profile', 'member', 'account', 'data'];
  for (final key in nestedKeys) {
    final nested = json[key];
    if (nested is Map) {
      final value = _readUserId(Map<String, dynamic>.from(nested));
      if (value > 0) return value;
    }
  }

  return 0;
}

Map<String, dynamic> _safeJsonMap(String body) {
  try {
    if (body.trim().isEmpty) return {};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return {};
}

class FollowService {
  Future<String> _token() async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token жоқ. Қайта login жаса.');
    }
    return token;
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    final token = await _token();

    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _safeJsonMap(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    throw Exception(
      (data['message'] ?? 'Request failed (${res.statusCode})').toString(),
    );
  }

  Future<void> _sendNoBody(String method, String url) async {
    final token = await _token();

    late http.Response res;

    if (method == 'POST') {
      res = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
    } else if (method == 'DELETE') {
      res = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
    } else {
      throw Exception('Unsupported method');
    }

    final data = _safeJsonMap(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }

    throw Exception(
      (data['message'] ?? 'Request failed (${res.statusCode})').toString(),
    );
  }

  Future<SearchUserResult?> findByNickname(String nickname) async {
    final token = await _token();

    final safeNickname = nickname.trim();
    if (safeNickname.isEmpty) return null;

    final uri = Uri.parse('${AuthService.baseUrl}/user/search').replace(
      queryParameters: {'nickname': safeNickname},
    );

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 404) return null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);

      dynamic rawUser;

      if (decoded is List) {
        if (decoded.isEmpty) return null;
        rawUser = decoded.first;
      } else if (decoded is Map) {
        rawUser = decoded['user'] ??
            decoded['data'] ??
            decoded['items'] ??
            decoded['results'] ??
            decoded;

        if (rawUser is List) {
          if (rawUser.isEmpty) return null;
          rawUser = rawUser.first;
        }
      }

      if (rawUser is! Map) {
        throw Exception('User response format is wrong');
      }

      final user = SearchUserResult.fromJson(
        Map<String, dynamic>.from(rawUser),
      );

      if (user.id <= 0) {
        throw Exception('Backend user id келген жоқ');
      }

      return user;
    }

    final data = _safeJsonMap(res.body);

    throw Exception(
      (data['message'] ?? 'User search failed (${res.statusCode})').toString(),
    );
  }

  Future<void> follow(int userId) async {
    if (userId <= 0) {
      throw Exception('User id дұрыс емес');
    }
    await _sendNoBody('POST', '${AuthService.baseUrl}/user/$userId/follow');
  }

  Future<void> unfollow(int userId) async {
    if (userId <= 0) {
      throw Exception('User id дұрыс емес');
    }
    await _sendNoBody('DELETE', '${AuthService.baseUrl}/user/$userId/follow');
  }

  Future<bool> isFollowing(int userId) async {
    if (userId <= 0) return false;

    final data = await _getJson(
      '${AuthService.baseUrl}/user/$userId/follow/status',
    );

    final value = data['isFollowing'] ?? data['following'] ?? data['status'];
    if (value is bool) return value;

    return value.toString().toLowerCase() == 'true';
  }

  Future<FollowCounts> getCounts(int userId) async {
    if (userId <= 0) {
      return FollowCounts(followersCount: 0, followingCount: 0);
    }

    final data = await _getJson(
      '${AuthService.baseUrl}/user/$userId/follow/counts',
    );
    return FollowCounts.fromJson(data);
  }

  Future<FollowPage> getFollowers({
    required int userId,
    int? cursor,
  }) async {
    final token = await _token();

    final uri = Uri.parse(
      '${AuthService.baseUrl}/user/$userId/followers',
    ).replace(
      queryParameters: {
        if (cursor != null) 'cursor': '$cursor',
      },
    );

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _safeJsonMap(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        (data['message'] ?? 'Followers load failed (${res.statusCode})')
            .toString(),
      );
    }

    final rawItems = data['items'] ?? data['followers'] ?? data['data'] ?? [];
    final items = rawItems is List ? rawItems : <dynamic>[];

    return FollowPage(
      items: items
          .whereType<Map>()
          .map((e) => FollowUser.fromJson(Map<String, dynamic>.from(e)))
          .where((u) => u.id > 0)
          .toList(),
      nextCursor: data['nextCursor'] == null ? null : _toInt(data['nextCursor']),
    );
  }

  Future<FollowPage> getFollowing({
    required int userId,
    int? cursor,
  }) async {
    final token = await _token();

    final uri = Uri.parse(
      '${AuthService.baseUrl}/user/$userId/following',
    ).replace(
      queryParameters: {
        if (cursor != null) 'cursor': '$cursor',
      },
    );

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = _safeJsonMap(res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        (data['message'] ?? 'Following load failed (${res.statusCode})')
            .toString(),
      );
    }

    final rawItems = data['items'] ?? data['following'] ?? data['data'] ?? [];
    final items = rawItems is List ? rawItems : <dynamic>[];

    return FollowPage(
      items: items
          .whereType<Map>()
          .map((e) => FollowUser.fromJson(Map<String, dynamic>.from(e)))
          .where((u) => u.id > 0)
          .toList(),
      nextCursor: data['nextCursor'] == null ? null : _toInt(data['nextCursor']),
    );
  }
}