// lib/screens/admin_alphabet_screen.dart
// ЕГЕР ҚАЛАСАҢ, compile-ready толық дұрыс вариант:

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/services/alphabet_prediction_service.dart';
import 'package:kazakh_learning_app/services/alphabet_service.dart';
import 'package:kazakh_learning_app/widgets/letter_recorder_button.dart';

class AdminAlphabetScreen extends StatefulWidget {
  const AdminAlphabetScreen({super.key});

  @override
  State<AdminAlphabetScreen> createState() => _AdminAlphabetScreenState();
}

class _AdminAlphabetScreenState extends State<AdminAlphabetScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  final AlphabetService service = AlphabetService();

  bool loading = true;
  List<AlphabetLetterVM> letters = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _errorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final data = await service.getAll();

      letters = data
          .map<AlphabetLetterVM>(
            (e) => AlphabetLetterVM.fromJson(Map<String, dynamic>.from(e)),
      )
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    } catch (e) {
      _errorSnack('Ошибка: $e');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _addOrEdit({AlphabetLetterVM? existing}) async {
    final result = await showModalBottomSheet<AlphabetLetterVM>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LetterEditorSheet(letter: existing),
    );

    if (result == null) return;

    try {
      final body = result.toApiJson();

      if (existing == null) {
        await service.create(body);
      } else {
        await service.update(existing.id, body);
      }

      await _load();
    } catch (e) {
      _errorSnack('Ошибка: $e');
    }
  }

  Future<void> _delete(AlphabetLetterVM l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Өшіру?'),
        content: Text('${l.uppercase} әрпін өшірейік пе?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Жоқ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Иә'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await service.delete(l.id);
      await _load();
    } catch (e) {
      _errorSnack('Delete error: $e');
    }
  }

  Future<void> _openLetter(AlphabetLetterVM l) async {
    final bool? refreshed = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminAlphabetLetterDetailScreen(letterId: l.id),
      ),
    );

    if (refreshed == true) {
      await _load();
    }
  }

  void _openFirstLetter() {
    if (loading) return;

    if (letters.isEmpty) {
      _errorSnack('Әзірге әріптер қосылмаған');
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
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                      ),
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
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => _addOrEdit(),
                      ),
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
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                onRefresh: _load,
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
                      child: Stack(
                        children: [
                          Container(
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
                                mainAxisAlignment:
                                MainAxisAlignment.center,
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
                          Positioned(
                            right: 2,
                            top: 2,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              onSelected: (v) {
                                if (v == 'edit') {
                                  _addOrEdit(existing: l);
                                }
                                if (v == 'delete') {
                                  _delete(l);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class AdminAlphabetLetterDetailScreen extends StatefulWidget {
  final int letterId;

  const AdminAlphabetLetterDetailScreen({
    super.key,
    required this.letterId,
  });

  @override
  State<AdminAlphabetLetterDetailScreen> createState() =>
      _AdminAlphabetLetterDetailScreenState();
}

class _AdminAlphabetLetterDetailScreenState
    extends State<AdminAlphabetLetterDetailScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);
  static const Color deep = Color(0xFF4B007D);

  final AlphabetService _service = AlphabetService();
  final AudioPlayer _player = AudioPlayer();

  bool _screenLoading = true;
  bool uploading = false;
  bool _audioLoading = false;
  bool _playing = false;
  bool _predictLoading = false;
  String? _recordedPath;
  AlphabetLetterVM? _letter;

  @override
  void initState() {
    super.initState();

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _playing = state == PlayerState.playing;
      });
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _audioLoading = false;
      });
    });

    _loadLetter();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadLetter() async {
    try {
      if (mounted) {
        setState(() => _screenLoading = true);
      }

      final data = await _service.getById(widget.letterId);
      final loaded = AlphabetLetterVM.fromJson(data);

      if (!mounted) return;
      setState(() {
        _letter = loaded;
        _screenLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _screenLoading = false);
      _toast('Load error: $e');
    }
  }

  Future<void> _pickAndUploadAudio() async {
    try {
      setState(() => uploading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'wav', 'ogg'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) {
          setState(() => uploading = false);
        }
        return;
      }

      final file = result.files.first;

      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          throw Exception('Web-та файл bytes жоқ');
        }

        await _service.uploadAudio(
          id: widget.letterId,
          fileName: file.name,
          fileBytes: bytes,
        );
      } else {
        final path = file.path;
        if (path == null || path.isEmpty) {
          throw Exception('Файл path жоқ');
        }

        await _service.uploadAudio(
          id: widget.letterId,
          fileName: file.name,
          filePath: path,
        );
      }

      await _loadLetter();

      if (!mounted) return;
      _toast('Audio сәтті жүктелді');
    } catch (e) {
      if (!mounted) return;
      _toast('Upload error: $e');
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
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
        _toast('This letter has no sound.');
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

      _toast('This letter has no sound.');
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _player.pause();
    } catch (e) {
      if (!mounted) return;
      _toast('Audio pause error: $e');
    }
  }

  Future<void> _predictRecordedVoice() async {
    final letter = _letter;
    final recordedPath = _recordedPath;

    if (letter == null) return;

    if (recordedPath == null || recordedPath.trim().isEmpty) {
      _toast('Алдымен микрофонмен өз даусыңды жазып ал');
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
      _toast('Тексеру error: $e');
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
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: uploading ? null : _pickAndUploadAudio,
                    icon: uploading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.upload_file_rounded),
                    label: Text(uploading ? 'Uploading...' : 'Upload audio'),
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
                    (cardW * 1.22).clamp(520.0, 760.0).toDouble();

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

class _LetterEditorSheet extends StatefulWidget {
  final AlphabetLetterVM? letter;

  const _LetterEditorSheet({required this.letter});

  @override
  State<_LetterEditorSheet> createState() => _LetterEditorSheetState();
}

class _LetterEditorSheetState extends State<_LetterEditorSheet> {
  static const Color purple = Color(0xFF8E5BFF);

  late final TextEditingController orderC;
  late final TextEditingController uppercaseC;
  late final TextEditingController lowercaseC;
  late final TextEditingController pronunciationRuC;
  late final TextEditingController pronunciationEnC;
  late final TextEditingController descriptionRuC;
  late final TextEditingController descriptionEnC;
  late final TextEditingController examplesC;

  @override
  void initState() {
    super.initState();

    final l = widget.letter;

    orderC = TextEditingController(text: (l?.orderIndex ?? 0).toString());
    uppercaseC = TextEditingController(text: l?.uppercase ?? '');
    lowercaseC = TextEditingController(text: l?.lowercase ?? '');
    pronunciationRuC = TextEditingController(text: l?.pronunciationRu ?? '');
    pronunciationEnC = TextEditingController(text: l?.pronunciationEn ?? '');
    descriptionRuC = TextEditingController(text: l?.descriptionRu ?? '');
    descriptionEnC = TextEditingController(text: l?.descriptionEn ?? '');
    examplesC = TextEditingController(
      text: l == null
          ? ''
          : l.examples.map((e) => '${e.kz}|${e.ru}|${e.en}').join('\n'),
    );
  }

  @override
  void dispose() {
    orderC.dispose();
    uppercaseC.dispose();
    lowercaseC.dispose();
    pronunciationRuC.dispose();
    pronunciationEnC.dispose();
    descriptionRuC.dispose();
    descriptionEnC.dispose();
    examplesC.dispose();
    super.dispose();
  }

  List<AlphabetExampleVM> _parseExamples(String raw) {
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final result = <AlphabetExampleVM>[];

    for (final line in lines) {
      final parts = line.split('|');
      if (parts.length >= 3) {
        result.add(
          AlphabetExampleVM(
            kz: parts[0].trim(),
            ru: parts[1].trim(),
            en: parts[2].trim(),
          ),
        );
      }
    }

    return result;
  }

  void _save() {
    final order = int.tryParse(orderC.text.trim()) ?? 0;
    final uppercase = uppercaseC.text.trim();
    final lowercase = lowercaseC.text.trim();

    if (uppercase.isEmpty || lowercase.isEmpty) return;

    Navigator.pop(
      context,
      AlphabetLetterVM(
        id: widget.letter?.id ?? 0,
        orderIndex: order,
        uppercase: uppercase,
        lowercase: lowercase,
        pronunciationRu: pronunciationRuC.text.trim(),
        pronunciationEn: pronunciationEnC.text.trim(),
        descriptionRu: descriptionRuC.text.trim(),
        descriptionEn: descriptionEnC.text.trim(),
        examples: _parseExamples(examplesC.text),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: inset),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F1FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.letter == null ? 'Add letter' : 'Edit letter',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _field(
                controller: orderC,
                label: 'OrderIndex',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _field(
                controller: uppercaseC,
                label: 'Uppercase',
                hint: 'Ә',
              ),
              const SizedBox(height: 10),
              _field(
                controller: lowercaseC,
                label: 'Lowercase',
                hint: 'ә',
              ),
              const SizedBox(height: 10),
              _field(
                controller: pronunciationRuC,
                label: 'Pronunciation RU',
                hint: "похоже на мягкое 'а'",
              ),
              const SizedBox(height: 10),
              _field(
                controller: pronunciationEnC,
                label: 'Pronunciation EN',
                hint: "similar to 'a' in cat",
              ),
              const SizedBox(height: 10),
              _field(
                controller: descriptionRuC,
                label: 'Description RU',
                maxLines: 3,
                hint: 'гласная переднего ряда',
              ),
              const SizedBox(height: 10),
              _field(
                controller: descriptionEnC,
                label: 'Description EN',
                maxLines: 3,
                hint: 'front vowel',
              ),
              const SizedBox(height: 10),
              _field(
                controller: examplesC,
                label: 'Examples',
                maxLines: 6,
                hint: 'әке|отец|father\nәлем|мир|world',
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Формат examples: kz|ru|en (әр жолға бір example)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
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

  Map<String, dynamic> toApiJson() => {
    'orderIndex': orderIndex,
    'uppercase': uppercase,
    'lowercase': lowercase,
    'pronunciationRu': pronunciationRu,
    'pronunciationEn': pronunciationEn,
    'descriptionRu': descriptionRu,
    'descriptionEn': descriptionEn,
    'examples': examples.map((e) => e.toJson()).toList(),
  };

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

  Map<String, dynamic> toJson() => {
    'kz': kz,
    'ru': ru,
    'en': en,
  };

  factory AlphabetExampleVM.fromJson(Map<String, dynamic> j) {
    return AlphabetExampleVM(
      kz: (j['kz'] ?? '').toString(),
      ru: (j['ru'] ?? '').toString(),
      en: (j['en'] ?? '').toString(),
    );
  }
}