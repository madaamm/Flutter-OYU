import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  static const red = Color(0xFFC9535C);

  final TextEditingController topicController = TextEditingController();
  final AudioRecorder recorder = AudioRecorder();

  bool isRecording = false;
  bool isLoading = false;

  Map<String, dynamic>? result;

  final String apiUrl = 'https://oyuml.onrender.com/api/speaking-api/evaluate';

  @override
  void dispose() {
    topicController.dispose();
    recorder.dispose();
    super.dispose();
  }

  Future<void> toggleRecording() async {
    if (isLoading) return;

    if (isRecording) {
      await stopAndSendRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    final hasPermission = await recorder.hasPermission();

    if (!hasPermission) {
      showMessage('Микрофонға рұқсат керек');
      return;
    }

    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    setState(() {
      isRecording = true;
      result = null;
    });
  }

  Future<void> stopAndSendRecording() async {
    final audioPath = await recorder.stop();

    setState(() {
      isRecording = false;
    });

    if (audioPath == null) {
      showMessage('Аудио жазылмады');
      return;
    }

    await sendToBackend(audioPath);
  }

  Future<void> sendToBackend(String audioPath) async {
    setState(() {
      isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(apiUrl),
      );

      request.fields['topic'] = topicController.text.trim();
      request.fields['language'] = 'ru';

      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioPath,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final data = jsonDecode(response.body);

      setState(() {
        result = data;
      });
    } catch (e) {
      showMessage('Қате: $e');
    } finally {
      setState(() {
        isLoading = false;
      });

      final file = File(audioPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget buildResult() {
    if (result == null) return const SizedBox();

    final scores = result!['scores'] ?? {};

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feedback',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Overall score: ${result!['overall_score'] ?? 0}/10',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Text('Fluency: ${scores['fluency'] ?? 0}'),
          Text('Pronunciation: ${scores['pronunciation'] ?? 0}'),
          Text('Grammar: ${scores['grammar'] ?? 0}'),
          Text('Vocabulary: ${scores['vocabulary'] ?? 0}'),
          Text('Coherence: ${scores['coherence'] ?? 0}'),

          const SizedBox(height: 12),

          const Text(
            'Transcript:',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(result!['transcript'] ?? ''),

          const SizedBox(height: 12),

          const Text(
            'Summary:',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(result!['summary'] ?? ''),

          const SizedBox(height: 12),

          if (result!['tips'] is List)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tips:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                ...List.from(result!['tips']).map(
                      (tip) => Text('• $tip'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = isRecording ? 'Stop & Send' : 'Start speaking';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 22,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Speaking',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 60, 28, 32),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: topicController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Напишите тему, о которой будете говорить...',
                          hintStyle: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF777777),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.25,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.62,
                      height: 82,
                      child: ElevatedButton(
                        onPressed: toggleRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isRecording ? Colors.black87 : red,
                          elevation: 6,
                          shadowColor: Colors.black.withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isRecording
                                  ? Icons.stop_rounded
                                  : Icons.mic_none_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      isRecording
                          ? 'Recording... сөйлеңіз'
                          : 'Тақырыпты жазып, батырманы басыңыз',
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 15,
                      ),
                    ),

                    buildResult(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}