import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/l10n/app_text.dart';

import '../services/auth_service.dart';

class AlphabetGame {
  final String type;
  final String title;
  final String? question;
  final String? audioUrl;
  final String correctAnswer;
  final List<String> options;

  AlphabetGame({
    required this.type,
    required this.title,
    required this.correctAnswer,
    required this.options,
    this.question,
    this.audioUrl,
  });

  factory AlphabetGame.fromJson(Map<String, dynamic> json) {
    return AlphabetGame(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      question: json['question']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
      correctAnswer: json['correctAnswer'] ?? '',
      options: List<String>.from(json['options'] ?? []),
    );
  }
}

class AlphabetGameScreen extends StatefulWidget {
  const AlphabetGameScreen({super.key});

  @override
  State<AlphabetGameScreen> createState() => _AlphabetGameScreenState();
}

class _AlphabetGameScreenState extends State<AlphabetGameScreen> {
  static const purple = Color(0xFF8E5BFF);

  final AudioPlayer _player = AudioPlayer();

  AlphabetGame? game;
  bool loading = true;
  bool answered = false;
  bool correct = false;
  String? selectedAnswer;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadGame() async {
    try {
      setState(() {
        loading = true;
        answered = false;
        selectedAnswer = null;
      });

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/alphabet-game/random'),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final json = jsonDecode(response.body);

      if (!mounted) return;
      setState(() {
        game = AlphabetGame.fromJson(json);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _playAudio() async {
    if (game == null || game!.audioUrl == null || game!.audioUrl!.isEmpty) {
      return;
    }

    final base = AuthService.baseUrl;
    final relative = game!.audioUrl!;
    final url = Uri.parse(base).resolve(relative).toString();

    try {
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('Audio play error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('audio_play_failed'))),
      );
    }
  }

  void _selectAnswer(String answer) {
    if (answered || game == null) return;

    setState(() {
      selectedAnswer = answer;
      correct = answer == game!.correctAnswer;
      answered = true;
    });
  }

  Color _optionColor(String option) {
    if (!answered || game == null) return Colors.white;
    if (option == game!.correctAnswer) return Colors.green;
    if (option == selectedAnswer) return Colors.red;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: purple,
        title: Text(context.tr('alphabet_game')),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : game == null
              ? Center(child: Text(context.tr('game_not_found')))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        game!.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (game!.type == 'audio')
                        ElevatedButton.icon(
                          onPressed: _playAudio,
                          icon: const Icon(Icons.volume_up),
                          label: Text(context.tr('play_audio')),
                        ),
                      if (game!.question != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            game!.question!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: ListView.separated(
                          itemCount: game!.options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final option = game!.options[i];
                            return SizedBox(
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () => _selectAnswer(option),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _optionColor(option),
                                ),
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (answered)
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              correct
                                  ? context.tr('correct')
                                  : context.tr('wrong'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: correct ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _loadGame,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple,
                                ),
                                child: Text(
                                  context.tr('next'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }
}
