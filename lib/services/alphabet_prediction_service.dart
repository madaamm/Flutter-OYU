import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/audio_file_bytes_loader.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';

class LetterPredictionResult {
  final String predictedLetter;
  final double confidencePercent;
  final Map<String, dynamic> raw;

  const LetterPredictionResult({
    required this.predictedLetter,
    required this.confidencePercent,
    required this.raw,
  });

  factory LetterPredictionResult.fromJson(Map<String, dynamic> json) {
    final predicted = _extractPredictedLetter(json);
    final confidence = _extractConfidencePercent(json);

    return LetterPredictionResult(
      predictedLetter: predicted,
      confidencePercent: confidence,
      raw: json,
    );
  }

  static String _extractPredictedLetter(Map<String, dynamic> json) {
    final candidates = [
      json['predictedLetter'],
      json['predicted_letter'],
      json['letter'],
      json['prediction'],
      json['result'],
      json['class'],
      json['label'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'Белгісіз';
  }

  static double _extractConfidencePercent(Map<String, dynamic> json) {
    final candidates = [
      json['confidence'],
      json['confidence_percent'],
      json['confidencePercent'],
      json['score'],
      json['probability'],
      json['accuracy'],
    ];

    for (final value in candidates) {
      final number = _toDouble(value);
      if (number == null) continue;

      if (number <= 1) {
        return (number * 100).clamp(0, 100).toDouble();
      }

      return number.clamp(0, 100).toDouble();
    }

    return 0;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class AlphabetPredictionService {
  AlphabetPredictionService._();

  static const String _predictUrl =
      'https://oyuml.onrender.com/api/alphabet/predict-letter';

  static Future<LetterPredictionResult> predictLetter({
    required int letterId,
    required String recordedPath,
    required String expectedUppercase,
    required String expectedLowercase,
  }) async {
    if (recordedPath.trim().isEmpty) {
      throw Exception('Жазылған дауыс табылмады');
    }

    final fileBytes = await loadRecordedAudioBytes(recordedPath);
    final filename = _resolveFileName(recordedPath);
    final contentType = _resolveContentType(filename);

    final attempts = <String>['file', 'audio', 'voice'];
    http.Response? lastResponse;
    Object? lastError;

    for (final fieldName in attempts) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(_predictUrl),
        );

        request.headers['Accept'] = 'application/json';

        final token = await AuthService().getToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields['letterId'] = letterId.toString();
        request.fields['expectedUppercase'] = expectedUppercase;
        request.fields['expectedLowercase'] = expectedLowercase;
        request.fields['expectedLetter'] = expectedUppercase;

        request.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            fileBytes,
            filename: filename,
            contentType: contentType,
          ),
        );

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        lastResponse = response;

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = response.body.trim();
          if (body.isEmpty) {
            throw Exception('Predict API бос жауап қайтарды');
          }

          final decoded = jsonDecode(body);
          if (decoded is! Map<String, dynamic>) {
            throw Exception('Predict API object қайтармады');
          }

          return LetterPredictionResult.fromJson(decoded);
        }

        if (response.statusCode == 400 ||
            response.statusCode == 404 ||
            response.statusCode == 415 ||
            response.statusCode == 422) {
          continue;
        }

        throw Exception(
          'Predict API error: ${response.statusCode} ${response.body}',
        );
      } catch (e) {
        lastError = e;
      }
    }

    if (lastResponse != null) {
      throw Exception(
        'Predict API error: ${lastResponse.statusCode} ${lastResponse.body}',
      );
    }

    throw Exception('Predict request failed: $lastError');
  }

  static String _resolveFileName(String path) {
    final lower = path.toLowerCase();

    if (lower.contains('.wav')) {
      return 'recorded_letter.wav';
    }
    if (lower.contains('.ogg')) {
      return 'recorded_letter.ogg';
    }
    if (lower.contains('.mp3')) {
      return 'recorded_letter.mp3';
    }
    if (lower.contains('.m4a')) {
      return 'recorded_letter.m4a';
    }
    if (lower.contains('.aac')) {
      return 'recorded_letter.aac';
    }

    return 'recorded_letter.wav';
  }

  static http.MediaType _resolveContentType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.wav')) {
      return http.MediaType('audio', 'wav');
    }
    if (lower.endsWith('.ogg')) {
      return http.MediaType('audio', 'ogg');
    }
    if (lower.endsWith('.mp3')) {
      return http.MediaType('audio', 'mpeg');
    }
    if (lower.endsWith('.m4a')) {
      return http.MediaType('audio', 'mp4');
    }
    if (lower.endsWith('.aac')) {
      return http.MediaType('audio', 'aac');
    }

    return http.MediaType('application', 'octet-stream');
  }
}