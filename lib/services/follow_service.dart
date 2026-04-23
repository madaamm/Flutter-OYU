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
    return FollowUser(
      id: _toInt(json['id']),
      username: (json['username'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      level: (json['level'] ?? 'A0').toString(),
      xp: _toInt(json['xp']),
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
      id: _toInt(json['id']),
      username: (json['username'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      level: (json['level'] ?? 'A0').toString(),
      xp: _toInt(json['xp']),
      email: (json['email'] ?? '').toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse('${value ?? 0}') ?? 0;
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
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> data = {};
    try {
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      }
    } catch (_) {}

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
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } else if (method == 'DELETE') {
      res = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } else {
      throw Exception('Unsupported method');
    }

    Map<String, dynamic> data = {};
    try {
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      }
    } catch (_) {}

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

    final res = await http.get(
      Uri.parse('${AuthService.baseUrl}/user/by-nickname/$safeNickname'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 404) {
      return null;
    }

    Map<String, dynamic> data = {};
    try {
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      }
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final userMap = (data['user'] is Map<String, dynamic>)
          ? data['user'] as Map<String, dynamic>
          : data;

      return SearchUserResult.fromJson(userMap);
    }

    throw Exception(
      (data['message'] ?? 'User search failed (${res.statusCode})').toString(),
    );
  }

  Future<void> follow(int userId) async {
    await _sendNoBody('POST', '${AuthService.baseUrl}/user/$userId/follow');
  }

  Future<void> unfollow(int userId) async {
    await _sendNoBody('DELETE', '${AuthService.baseUrl}/user/$userId/follow');
  }

  Future<bool> isFollowing(int userId) async {
    final data = await _getJson(
      '${AuthService.baseUrl}/user/$userId/follow/status',
    );

    final value = data['isFollowing'] ?? data['following'] ?? data['status'];
    if (value is bool) return value;

    return value.toString().toLowerCase() == 'true';
  }

  Future<FollowCounts> getCounts(int userId) async {
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
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> data = {};
    try {
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      }
    } catch (_) {}

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        (data['message'] ?? 'Followers load failed (${res.statusCode})')
            .toString(),
      );
    }

    final rawItems = (data['items'] ??
        data['followers'] ??
        data['data'] ??
        <dynamic>[]) as List<dynamic>;

    return FollowPage(
      items: rawItems
          .whereType<Map>()
          .map((e) => FollowUser.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      nextCursor: data['nextCursor'] == null
          ? null
          : _toInt(data['nextCursor']),
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
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    Map<String, dynamic> data = {};
    try {
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      }
    } catch (_) {}

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        (data['message'] ?? 'Following load failed (${res.statusCode})')
            .toString(),
      );
    }

    final rawItems = (data['items'] ??
        data['following'] ??
        data['data'] ??
        <dynamic>[]) as List<dynamic>;

    return FollowPage(
      items: rawItems
          .whereType<Map>()
          .map((e) => FollowUser.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      nextCursor: data['nextCursor'] == null
          ? null
          : _toInt(data['nextCursor']),
    );
  }
}