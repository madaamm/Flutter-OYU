import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/models/dictionary_entry_model.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';

class SaveDictionaryWordResult {
  final DictionaryEntryModel entry;
  final bool alreadySaved;
  final bool foundInGlobalDictionary;
  final String message;

  const SaveDictionaryWordResult({
    required this.entry,
    required this.alreadySaved,
    required this.foundInGlobalDictionary,
    required this.message,
  });
}

class DictionaryService {
  Future<Map<String, String>> _headers({bool withJson = false}) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token missing');
    }

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
    };

    if (withJson) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  Map<String, dynamic> _safeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return <String, dynamic>{};
  }

  List<DictionaryEntryModel> _safeList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => DictionaryEntryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return <DictionaryEntryModel>[];
  }

  Future<List<DictionaryEntryModel>> getMyDictionary() async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/user/dictionary'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load dictionary (${response.statusCode})');
    }

    return _safeList(response.body);
  }

  Future<SaveDictionaryWordResult> saveWord(String word) async {
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/user/dictionary'),
      headers: await _headers(withJson: true),
      body: jsonEncode({'word': word}),
    );

    final decoded = _safeMap(response.body);
    final entryJson = decoded['entry'];

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        (decoded['message'] ?? 'Failed to save word (${response.statusCode})').toString(),
      );
    }

    if (entryJson is! Map) {
      throw Exception('Dictionary entry was not returned');
    }

    return SaveDictionaryWordResult(
      entry: DictionaryEntryModel.fromJson(Map<String, dynamic>.from(entryJson)),
      alreadySaved: decoded['alreadySaved'] == true,
      foundInGlobalDictionary: decoded['foundInGlobalDictionary'] == true,
      message: (decoded['message'] ?? 'Saved').toString(),
    );
  }

  Future<void> deleteEntry(int id) async {
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/user/dictionary/$id'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      final decoded = _safeMap(response.body);
      throw Exception(
        (decoded['message'] ?? 'Failed to delete word (${response.statusCode})').toString(),
      );
    }
  }
}
