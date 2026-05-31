import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/alphabet_prediction_service.dart';
import 'package:kazakh_learning_app/services/alphabet_service.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/widgets/letter_recorder_button.dart';
import 'package:kazakh_learning_app/screens/alphabet_game_screen.dart';
import 'package:kazakh_learning_app/services/language_service.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  static const Color purple = Color(0xFF3D0067);
  static const Color yellow = Color(0xFFFDC500);
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

  void _openLetter(AlphabetLetterVM letter, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserAlphabetLetterDetailScreen(
          allLetters: letters,
          currentIndex: index,
        ),
      ),
    );
  }

  void _openGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AlphabetGameScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      const Spacer(),
                      const Text('Alphabet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('PLAY ALPHABET GAME', style: TextStyle(fontWeight: FontWeight.w900)),
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
                          onTap: () => _openLetter(l, i),
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
  final List<AlphabetLetterVM> allLetters; // весь список букв
  final int currentIndex;                  // индекс текущей буквы в списке

  const UserAlphabetLetterDetailScreen({
    super.key,
    required this.allLetters,
    required this.currentIndex,
  });

  @override
  State<UserAlphabetLetterDetailScreen> createState() =>
      _UserAlphabetLetterDetailScreenState();
}

class _UserAlphabetLetterDetailScreenState
    extends State<UserAlphabetLetterDetailScreen> {
  static const Color purple = Color(0xFF3D0067);
  static const Color yellow = Color(0xFFFDC500);
  static const Color bg = Color(0xFFF6F1FF);
  static const Color deep = Color(0xFF4B007D);

  final AudioPlayer _player = AudioPlayer();
  final AlphabetService _service = AlphabetService();

  bool _screenLoading = false; // теперь не нужна начальная загрузка, т.к. данные уже есть
  bool _playing = false;
  bool _audioLoading = false;
  bool _predictLoading = false;
  String? _recordedPath;

  late List<AlphabetLetterVM> _allLetters;
  late int _currentIndex;
  AlphabetLetterVM get _letter => _allLetters[_currentIndex];

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<void>? _playerCompleteSub;

  @override
  void initState() {
    super.initState();
    _allLetters = widget.allLetters;
    _currentIndex = widget.currentIndex;

    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final isPlayingNow = state == PlayerState.playing;
      if (_playing != isPlayingNow) {
        setState(() => _playing = isPlayingNow);
      }
    });

    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _audioLoading = false;
      });
    });
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

  String _getLocalizedPronunciation(AlphabetLetterVM letter, String lang) {
    switch (lang) {
      case 'en':
        return letter.pronunciationEn.isNotEmpty ? letter.pronunciationEn : letter.pronunciationRu;
      case 'ru':
      default:
        return letter.pronunciationRu.isNotEmpty ? letter.pronunciationRu : letter.pronunciationEn;
    }
  }

  String _getLocalizedDescription(AlphabetLetterVM letter, String lang) {
    switch (lang) {
      case 'en':
        return letter.descriptionEn.isNotEmpty ? letter.descriptionEn : letter.descriptionRu;
      case 'ru':
      default:
        return letter.descriptionRu.isNotEmpty ? letter.descriptionRu : letter.descriptionEn;
    }
  }

  String _getLocalizedExampleText(AlphabetExampleVM example, String lang) {
    switch (lang) {
      case 'en':
        return example.en;
      case 'kz':
        return example.kz;
      case 'ru':
      default:
        return example.ru;
    }
  }

  String _getExamplesTitle(String lang) {
    switch (lang) {
      case 'en': return 'Examples';
      case 'kz': return 'Мысалдар';
      default: return 'Примеры';
    }
  }

  Future<void> _playAudio() async {
    final letter = _letter;
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
          const SnackBar(content: Text('This letter has no sound.')),
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
        const SnackBar(content: Text('This letter has no sound.')),
      );
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _player.pause();
    } catch (e) {
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
        const SnackBar(content: Text('Алдымен микрофонмен өз даусыңды жазып ал')),
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
                Text('Expected letter: ${letter.uppercase}${letter.lowercase}'),
                const SizedBox(height: 8),
                Text('Predicted letter: ${result.predictedLetter}'),
                const SizedBox(height: 8),
                Text('Accuracy: ${percent.toStringAsFixed(1)}%'),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
        SnackBar(content: Text('Тексеру error: $e')),
      );
    }
  }

  // --- НАВИГАЦИЯ МЕЖДУ БУКВАМИ ---
  void _goToPrev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _recordedPath = null;
        _playing = false;
        _audioLoading = false;
        _predictLoading = false;
      });
    }
  }

  void _goToNext() {
    if (_currentIndex < _allLetters.length - 1) {
      setState(() {
        _currentIndex++;
        _recordedPath = null;
        _playing = false;
        _audioLoading = false;
        _predictLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allLetters.isEmpty) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final letter = _letter;
    final examples = letter.examples;
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < _allLetters.length - 1;
    final currentLang = LanguageService().currentLanguage;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: purple),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${letter.uppercase}${letter.lowercase}',
          style: const TextStyle(color: purple, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Карточка с информацией
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Буква и произношение (фиксированный верх)
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '${letter.uppercase}${letter.lowercase}',
                                style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: purple),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getLocalizedPronunciation(letter, currentLang),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Прокручиваемая область (описание + примеры)
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Локализованное описание
                                if (_getLocalizedDescription(letter, currentLang).isNotEmpty) ...[
                                  Text(
                                    currentLang == 'en' ? 'Description' : (currentLang == 'kz' ? 'Сипаттама' : 'Описание'),
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: purple),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _getLocalizedDescription(letter, currentLang),
                                    style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Локализованные примеры
                                Text(
                                  _getExamplesTitle(currentLang),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: purple),
                                ),
                                const SizedBox(height: 8),
                                if (examples.isEmpty)
                                  Text(
                                    currentLang == 'en' ? '— no examples yet —' : (currentLang == 'kz' ? '— мысалдар жоқ —' : '— примеры пока не добавлены —'),
                                    style: TextStyle(color: Colors.grey[600]),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: examples.map((e) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          _getLocalizedExampleText(e, currentLang),
                                          style: TextStyle(color: Colors.grey[800]),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Фиксированные кнопки внизу
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LetterRecorderButton(
                              onRecorded: (path) {
                                setState(() => _recordedPath = path);
                              },
                            ),
                            const SizedBox(width: 20),
                            _SquareBtn(
                              icon: _audioLoading
                                  ? Icons.hourglass_top_rounded
                                  : (_playing ? Icons.pause_circle_filled : Icons.headphones),
                              onTap: _playing ? _pauseAudio : _playAudio,
                              loading: _audioLoading,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _predictLoading ? null : _predictRecordedVoice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: deep,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: _predictLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.verified_rounded),
                            label: Text(
                              _predictLoading
                                  ? (currentLang == 'en' ? 'Checking...' : (currentLang == 'kz' ? 'Тексерілуде...' : 'Проверка...'))
                                  : (currentLang == 'en' ? 'Send for verification' : (currentLang == 'kz' ? 'Дауысты тексеруге жіберу' : 'Отправить на проверку')),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Кнопки навигации между буквами
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hasPrev ? _goToPrev : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: purple),
                        ),
                      ),
                      child: Text(currentLang == 'en' ? '← Previous' : (currentLang == 'kz' ? '← Алдыңғы' : '← Предыдущая')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hasNext ? _goToNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(currentLang == 'en' ? 'Next →' : (currentLang == 'kz' ? 'Келесі →' : 'Следующая →')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
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