import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/alphabet_prediction_service.dart';
import 'package:kazakh_learning_app/services/alphabet_service.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/widgets/letter_recorder_button.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  bool loading = true;
  String? error;
  List<AlphabetLetterVM> letters = [];

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/alphabet'),
        headers: const {
          'Accept': 'application/json',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          final loaded = decoded
              .whereType<Map>()
              .map(
                (e) => AlphabetLetterVM.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
              .toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

          if (mounted) {
            setState(() {
              letters = loaded;
            });
          }
        } else {
          throw Exception('Alphabet response list емес');
        }
      } else {
        throw Exception('Alphabet load error: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _openLetter(AlphabetLetterVM letter) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => UserAlphabetLetterDetailScreen(letterId: letter.id),
      ),
    );
  }

  void _openFirstLetter() {
    if (loading) return;

    if (letters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Әзірге әріптер қосылмаған'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _openLetter(letters.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 170,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              decoration: const BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      const Spacer(),
                      const Text(
                        'Alphabet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openFirstLetter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'LEARN THE LETTERS',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadLetters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: purple,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Қайта жүктеу'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (letters.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _loadLetters,
                      color: purple,
                      child: ListView(
                        children: const [
                          SizedBox(height: 140),
                          Center(
                            child: Text(
                              'Әзірге әріптер қосылмаған',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Admin әріп қосқанда мұнда автоматты шығады',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadLetters,
                    color: purple,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                      itemCount: letters.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, i) {
                        final l = letters[i];

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _openLetter(l),
                          child: Container(
                            decoration: BoxDecoration(
                              color: purple.withOpacity(0.72),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l.uppercase,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      l.primaryPronunciation,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserAlphabetLetterDetailScreen extends StatefulWidget {
  final int letterId;

  const UserAlphabetLetterDetailScreen({
    super.key,
    required this.letterId,
  });

  @override
  State<UserAlphabetLetterDetailScreen> createState() =>
      _UserAlphabetLetterDetailScreenState();
}

class _UserAlphabetLetterDetailScreenState
    extends State<UserAlphabetLetterDetailScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);
  static const Color deep = Color(0xFF4B007D);

  final AudioPlayer _player = AudioPlayer();
  final AlphabetService _service = AlphabetService();

  bool _screenLoading = true;
  bool _playing = false;
  bool _audioLoading = false;
  bool _predictLoading = false;
  String? _recordedPath;
  AlphabetLetterVM? _letter;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<void>? _playerCompleteSub;

  @override
  void initState() {
    super.initState();

    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final isPlayingNow = state == PlayerState.playing;
      if (_playing != isPlayingNow) {
        setState(() {
          _playing = isPlayingNow;
        });
      }
    });

    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _audioLoading = false;
      });
    });

    _loadLetter();
  }

  Future<void> _loadLetter() async {
    try {
      if (mounted) {
        setState(() => _screenLoading = true);
      }

      final res = await http.get(
        Uri.parse('${AuthService.baseUrl}/alphabet/${widget.letterId}'),
        headers: const {'Accept': 'application/json'},
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Letter load error: ${res.statusCode} ${res.body}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Letter response object емес');
      }

      if (!mounted) return;
      setState(() {
        _letter = AlphabetLetterVM.fromJson(decoded);
        _screenLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _screenLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _playerCompleteSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _withCacheBuster(String url) {
    final uri = Uri.parse(url);
    final updatedParams = Map<String, String>.from(uri.queryParameters);
    updatedParams['t'] = DateTime.now().millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: updatedParams).toString();
  }

  Future<void> _playAudio() async {
    final letter = _letter;
    if (letter == null) return;

    final String url = letter.audioApiUrl.trim().isNotEmpty
        ? letter.audioApiUrl.trim()
        : _service.buildAudioApiUrl(letter.id);

    try {
      setState(() => _audioLoading = true);

      final exists = await _service.audioExists(letter.id);
      if (!exists) {
        if (!mounted) return;
        setState(() => _audioLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This letter has no sound.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await _player.stop();
      await _player.play(UrlSource(_withCacheBuster(url)));

      if (!mounted) return;
      setState(() => _audioLoading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _audioLoading = false;
        _playing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This letter has no sound.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _player.pause();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio pause error: $e')),
      );
    }
  }

  Future<void> _predictRecordedVoice() async {
    final letter = _letter;
    final recordedPath = _recordedPath;

    if (letter == null) return;

    if (recordedPath == null || recordedPath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Алдымен микрофонмен өз даусыңды жазып ал'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() => _predictLoading = true);

      final result = await AlphabetPredictionService.predictLetter(
        letterId: letter.id,
        recordedPath: recordedPath,
        expectedUppercase: letter.uppercase,
        expectedLowercase: letter.lowercase,
      );

      if (!mounted) return;
      setState(() => _predictLoading = false);

      final double percent = result.confidencePercent;
      final bool isExcellent = percent >= 95.0;

      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isExcellent ? 'Excellent' : 'Try again',
                  style: TextStyle(
                    color: isExcellent ? Colors.green : purple,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Expected letter: ${letter.uppercase}${letter.lowercase}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Predicted letter: ${result.predictedLetter}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accuracy: ${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _predictLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Тексеру error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_screenLoading || _letter == null) {
      return const Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final letter = _letter!;
    final examples = letter.examples;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final double cardW =
                    c.maxWidth.clamp(0.0, 380.0).toDouble();
                    final double cardH =
                    (cardW * 1.22).clamp(460.0, 720.0).toDouble();

                    return Center(
                      child: SizedBox(
                        width: cardW,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: -20,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  Container(
                                    width: cardW * 0.55,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: purple.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: cardW * 0.82,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: purple.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: -22,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  Container(
                                    width: cardW * 0.70,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: purple.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: cardW * 0.52,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: purple.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: cardH,
                              padding:
                              const EdgeInsets.fromLTRB(22, 26, 22, 22),
                              decoration: BoxDecoration(
                                color: purple.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 18,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${letter.uppercase}${letter.lowercase}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 64,
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          letter.primaryPronunciation,
                                          style: TextStyle(
                                            color:
                                            Colors.white.withOpacity(0.92),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics:
                                      const BouncingScrollPhysics(),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          if (letter.descriptionRu.isNotEmpty) ...[
                                            Text(
                                              'Описание (RU):',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.95),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              letter.descriptionRu,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.88),
                                                height: 1.45,
                                                fontWeight:
                                                FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                          if (letter.descriptionEn.isNotEmpty) ...[
                                            Text(
                                              'Description (EN):',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.95),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              letter.descriptionEn,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.88),
                                                height: 1.45,
                                                fontWeight:
                                                FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                          Text(
                                            '(examples):',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.90),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          if (examples.isEmpty)
                                            Text(
                                              '— examples not added yet —',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.88),
                                                height: 1.55,
                                                fontWeight:
                                                FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            )
                                          else
                                            Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: examples
                                                  .map(
                                                    (e) => Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                    bottom: 10,
                                                  ),
                                                  child: Text(
                                                    '• ${e.kz} — ${e.ru} — ${e.en}',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(
                                                          0.88),
                                                      height: 1.55,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              )
                                                  .toList(),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      LetterRecorderButton(
                                        onRecorded: (path) {
                                          setState(() {
                                            _recordedPath = path;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 22),
                                      _SquareBtn(
                                        icon: _audioLoading
                                            ? Icons.hourglass_top_rounded
                                            : (_playing
                                            ? Icons.pause_circle_filled
                                            : Icons.headphones),
                                        onTap:
                                        _playing ? _pauseAudio : _playAudio,
                                        loading: _audioLoading,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: _predictLoading
                                          ? null
                                          : _predictRecordedVoice,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: deep,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(14),
                                        ),
                                      ),
                                      icon: _predictLoading
                                          ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                          : const Icon(Icons.verified_rounded),
                                      label: Text(
                                        _predictLoading
                                            ? 'Тексеріліп жатыр...'
                                            : 'Тексеріске дауысты жіберу',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  const _SquareBtn({
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  static const Color deep = Color(0xFF4B007D);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: deep,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Center(
            child: loading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class AlphabetLetterVM {
  final int id;
  final int orderIndex;
  final String uppercase;
  final String lowercase;
  final String pronunciationRu;
  final String pronunciationEn;
  final String descriptionRu;
  final String descriptionEn;
  final String audioUrl;
  final String audioApiUrl;
  final List<AlphabetExampleVM> examples;

  AlphabetLetterVM({
    required this.id,
    required this.orderIndex,
    required this.uppercase,
    required this.lowercase,
    this.pronunciationRu = '',
    this.pronunciationEn = '',
    this.descriptionRu = '',
    this.descriptionEn = '',
    this.audioUrl = '',
    this.audioApiUrl = '',
    this.examples = const [],
  });

  String get primaryPronunciation {
    if (pronunciationEn.trim().isNotEmpty) return pronunciationEn.trim();
    if (pronunciationRu.trim().isNotEmpty) return pronunciationRu.trim();
    return '/—/';
  }

  factory AlphabetLetterVM.fromJson(Map<String, dynamic> j) {
    final rawExamples = j['examples'];
    final examples = <AlphabetExampleVM>[];

    if (rawExamples is List) {
      for (final item in rawExamples) {
        if (item is Map) {
          examples.add(
            AlphabetExampleVM.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final id = (j['id'] is int) ? j['id'] : int.tryParse('${j['id']}') ?? 0;

    return AlphabetLetterVM(
      id: id,
      orderIndex: (j['orderIndex'] is int)
          ? j['orderIndex']
          : int.tryParse('${j['orderIndex']}') ?? 0,
      uppercase: (j['uppercase'] ?? '').toString(),
      lowercase: (j['lowercase'] ?? '').toString(),
      pronunciationRu: (j['pronunciationRu'] ?? '').toString(),
      pronunciationEn: (j['pronunciationEn'] ?? '').toString(),
      descriptionRu: (j['descriptionRu'] ?? '').toString(),
      descriptionEn: (j['descriptionEn'] ?? '').toString(),
      audioUrl: (j['audioUrl'] ?? '').toString().trim(),
      audioApiUrl: (j['audioApiUrl'] ?? '').toString().trim(),
      examples: examples,
    );
  }
}

class AlphabetExampleVM {
  final String kz;
  final String ru;
  final String en;

  AlphabetExampleVM({
    required this.kz,
    required this.ru,
    required this.en,
  });

  factory AlphabetExampleVM.fromJson(Map<String, dynamic> j) {
    return AlphabetExampleVM(
      kz: (j['kz'] ?? '').toString(),
      ru: (j['ru'] ?? '').toString(),
      en: (j['en'] ?? '').toString(),
    );
  }
}