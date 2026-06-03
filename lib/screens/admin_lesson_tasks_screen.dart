import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/lesson_model.dart';
import 'package:kazakh_learning_app/models/task_model.dart';

import '../services/admin_task_service.dart';

class AdminLessonTasksScreen extends StatefulWidget {
  final LessonModel lesson;

  const AdminLessonTasksScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<AdminLessonTasksScreen> createState() => _AdminLessonTasksScreenState();
}

class _AdminLessonTasksScreenState extends State<AdminLessonTasksScreen> {
  static const Color purple = Color(0xFF5B18D6);
  static const Color lightBg = Color(0xFFF1F1F1);

  final AdminTaskService _service = AdminTaskService();
  late Future<List<TaskModel>> _futureTasks;

  @override
  void initState() {
    super.initState();
    _futureTasks = _service.getLessonTasks(widget.lesson.id);
  }

  Future<void> _reload() async {
    setState(() {
      _futureTasks = _service.getLessonTasks(widget.lesson.id);
    });
    await _futureTasks;
  }

  Future<void> _openAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _TaskDialog(lessonId: widget.lesson.id),
    );

    if (result == true) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added')),
      );
    }
  }

  Future<void> _openEditDialog(TaskModel task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _TaskDialog(
        lessonId: widget.lesson.id,
        task: task,
      ),
    );

    if (result == true) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated')),
      );
    }
  }

  Future<void> _toggleArchive(TaskModel task) async {
    try {
      await _service.archiveTask(
        taskId: task.id,
        isArchived: !task.isArchived,
      );
      await _reload();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(task.isArchived ? 'Task unarchived' : 'Task archived'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: purple,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      widget.lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openAddDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: purple,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Add',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: FutureBuilder<List<TaskModel>>(
                    future: _futureTasks,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: purple),
                        );
                      }

                      if (snapshot.hasError) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.68,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.cloud_off_rounded, size: 58, color: Colors.grey),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'Tasks failed to load',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: purple,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '${snapshot.error}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      final tasks = snapshot.data ?? [];

                      if (tasks.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 600,
                              child: Center(
                                child: Text(
                                  'No tasks yet',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: purple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _TaskCard(
                            task: task,
                            onEdit: () => _openEditDialog(task),
                            onArchive: () => _toggleArchive(task),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _TaskCard({
    required this.task,
    required this.onEdit,
    required this.onArchive,
  });

  static const Color purple = Color(0xFF5B18D6);

  String get _title {
    switch (task.type) {
      case 'AUDIO_DICTATION':
        return task.audioText.isNotEmpty ? task.audioText : 'Audio dictation';
      case 'AUDIO_TRANSLATE':
        return task.translateText.isNotEmpty ? task.translateText : 'Audio translate';
      case 'WORD_MATCH':
        return task.matchingPairs.isNotEmpty
            ? '${task.matchingPairs.length} matching pairs'
            : 'Word match';
      case 'SENTENCE_BUILD':
      default:
        return task.promptText.isNotEmpty ? task.promptText : 'Sentence build';
    }
  }

  IconData get _icon {
    switch (task.type) {
      case 'AUDIO_DICTATION':
        return Icons.hearing_rounded;
      case 'AUDIO_TRANSLATE':
        return Icons.record_voice_over_rounded;
      case 'WORD_MATCH':
        return Icons.compare_arrows_rounded;
      case 'SENTENCE_BUILD':
      default:
        return Icons.extension_rounded;
    }
  }

  String get _typeLabel {
    switch (task.type) {
      case 'AUDIO_DICTATION':
        return 'Audio dictation';
      case 'AUDIO_TRANSLATE':
        return 'Audio translate';
      case 'WORD_MATCH':
        return 'Word match';
      case 'SENTENCE_BUILD':
      default:
        return 'Sentence build';
    }
  }

  int get _itemsCount {
    if (task.type == 'WORD_MATCH') return task.matchingPairs.length;
    return task.optionsWords.length;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: task.isArchived ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: task.isArchived ? const Color(0xFFD3D3D3) : const Color(0xFFE7D8FF),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF8E2BFF), Color(0xFF4E0497)]),
              ),
              child: Icon(_icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: purple,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${task.promptLang} -> ${task.targetLang}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(text: _typeLabel),
                      _Tag(text: 'XP: ${task.xpReward}'),
                      _Tag(text: 'Order: ${task.orderIndex}'),
                      if (_itemsCount > 0) _Tag(text: 'Items: $_itemsCount'),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'archive') onArchive();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'archive', child: Text('Archive')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF5B18D6),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TaskDialog extends StatefulWidget {
  final int lessonId;
  final TaskModel? task;

  const _TaskDialog({
    required this.lessonId,
    this.task,
  });

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  static const Color purple = Color(0xFF5B18D6);

  static const String sentenceBuild = 'SENTENCE_BUILD';
  static const String audioDictation = 'AUDIO_DICTATION';
  static const String audioTranslate = 'AUDIO_TRANSLATE';
  static const String wordMatch = 'WORD_MATCH';

  final _formKey = GlobalKey<FormState>();
  final _service = AdminTaskService();

  late final TextEditingController _promptTextController;
  late final TextEditingController _optionsWordsController;
  late final TextEditingController _correctWordsController;
  late final TextEditingController _audioUrlController;
  late final TextEditingController _audioTextController;
  late final TextEditingController _translateTextController;
  late final TextEditingController _matchingPairsController;
  late final TextEditingController _xpRewardController;
  late final TextEditingController _orderIndexController;

  String _type = sentenceBuild;
  String _promptLang = 'RU';
  String _targetLang = 'KZ';
  bool _saving = false;
  bool _uploadingAudio = false;

  bool get isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;
    _type = task?.type.isNotEmpty == true ? task!.type : sentenceBuild;
    _promptLang = task?.promptLang.isNotEmpty == true ? task!.promptLang : 'RU';
    _targetLang = task?.targetLang.isNotEmpty == true ? task!.targetLang : 'KZ';

    _promptTextController = TextEditingController(text: task?.promptText ?? '');
    _optionsWordsController = TextEditingController(text: task?.optionsWords.join(', ') ?? '');
    _correctWordsController = TextEditingController(text: task?.correctWords.join(', ') ?? '');
    _audioUrlController = TextEditingController(text: task?.audioUrl ?? '');
    _audioTextController = TextEditingController(text: task?.audioText ?? '');
    _translateTextController = TextEditingController(text: task?.translateText ?? '');
    _matchingPairsController = TextEditingController(
      text: task == null ? '' : task.matchingPairs.map((e) => '${e.left}|${e.right}').join('\n'),
    );
    _xpRewardController = TextEditingController(text: (task?.xpReward ?? 10).toString());
    _orderIndexController = TextEditingController(text: (task?.orderIndex ?? 1).toString());
  }

  @override
  void dispose() {
    _promptTextController.dispose();
    _optionsWordsController.dispose();
    _correctWordsController.dispose();
    _audioUrlController.dispose();
    _audioTextController.dispose();
    _translateTextController.dispose();
    _matchingPairsController.dispose();
    _xpRewardController.dispose();
    _orderIndexController.dispose();
    super.dispose();
  }

  List<String> _splitWords(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<MatchingPair> _parseMatchingPairs(String value) {
    final lines = value
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final pairs = <MatchingPair>[];

    for (final line in lines) {
      final separator = line.contains('|')
          ? '|'
          : line.contains('=')
              ? '='
              : line.contains(':')
                  ? ':'
                  : null;

      if (separator == null) continue;

      final parts = line.split(separator);
      if (parts.length < 2) continue;

      final left = parts.first.trim();
      final right = parts.sublist(1).join(separator).trim();

      if (left.isEmpty || right.isEmpty) continue;

      pairs.add(
        MatchingPair(
          id: pairs.length + 1,
          left: left,
          right: right,
        ),
      );
    }

    return pairs;
  }

  String? _requiredTextValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _wordsValidator(String? value, String message) {
    if (_splitWords(value ?? '').isEmpty) return message;
    return null;
  }

  String? _matchingPairsValidator(String? value) {
    final pairs = _parseMatchingPairs(value ?? '');
    if (pairs.isEmpty) {
      return 'Enter matching pairs like: cat|мысық';
    }
    return null;
  }

  Future<void> _pickAndUploadAudio() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'ogg', 'flac', 'aac'],
        withData: true,
      );

      if (picked == null) return;
      final file = picked.files.single;

      if (file.bytes == null) {
        throw Exception('Audio file bytes not found. Pick the file again.');
      }

      setState(() => _uploadingAudio = true);
      final audioUrl = await _service.uploadTaskAudio(
        file: file,
        title: _promptTextController.text.trim().isNotEmpty
            ? _promptTextController.text.trim()
            : _audioTextController.text.trim().isNotEmpty
                ? _audioTextController.text.trim()
                : _translateTextController.text.trim(),
      );
      _audioUrlController.text = audioUrl;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio file uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio upload error: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAudio = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final xpReward = int.parse(_xpRewardController.text.trim());
      final orderIndex = int.parse(_orderIndexController.text.trim());

      String? promptText;
      List<String>? optionsWords;
      List<String>? correctWords;
      String? audioUrl;
      String? audioText;
      String? translateText;
      List<MatchingPair>? matchingPairs;

      switch (_type) {
        case sentenceBuild:
          promptText = _promptTextController.text.trim();
          optionsWords = _splitWords(_optionsWordsController.text);
          correctWords = _splitWords(_correctWordsController.text);
          break;
        case audioDictation:
          audioUrl = _audioUrlController.text.trim();
          audioText = _audioTextController.text.trim();
          break;
        case audioTranslate:
          audioUrl = _audioUrlController.text.trim();
          translateText = _translateTextController.text.trim();
          break;
        case wordMatch:
          matchingPairs = _parseMatchingPairs(_matchingPairsController.text);
          break;
      }

      if (isEdit) {
        await _service.updateTask(
          taskId: widget.task!.id,
          type: _type,
          promptLang: _promptLang,
          targetLang: _targetLang,
          promptText: promptText,
          optionsWords: optionsWords,
          correctWords: correctWords,
          audioUrl: audioUrl,
          audioText: audioText,
          translateText: translateText,
          matchingPairs: matchingPairs,
          xpReward: xpReward,
          orderIndex: orderIndex,
        );
      } else {
        await _service.createTask(
          lessonId: widget.lessonId,
          type: _type,
          promptLang: _promptLang,
          targetLang: _targetLang,
          promptText: promptText,
          optionsWords: optionsWords,
          correctWords: correctWords,
          audioUrl: audioUrl,
          audioText: audioText,
          translateText: translateText,
          matchingPairs: matchingPairs,
          xpReward: xpReward,
          orderIndex: orderIndex,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'Edit task' : 'Add new task',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: _decoration('Task type'),
                  items: const [
                    DropdownMenuItem(value: sentenceBuild, child: Text('Sentence build')),
                    DropdownMenuItem(value: audioDictation, child: Text('Audio dictation')),
                    DropdownMenuItem(value: audioTranslate, child: Text('Audio translate')),
                    DropdownMenuItem(value: wordMatch, child: Text('Word match')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _promptLang,
                  decoration: _decoration('Prompt language'),
                  items: const [
                    DropdownMenuItem(value: 'RU', child: Text('RU')),
                    DropdownMenuItem(value: 'KZ', child: Text('KZ')),
                    DropdownMenuItem(value: 'EN', child: Text('EN')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _promptLang = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _targetLang,
                  decoration: _decoration('Target language'),
                  items: const [
                    DropdownMenuItem(value: 'KZ', child: Text('KZ')),
                    DropdownMenuItem(value: 'RU', child: Text('RU')),
                    DropdownMenuItem(value: 'EN', child: Text('EN')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _targetLang = v);
                  },
                ),
                const SizedBox(height: 12),
                if (_type == sentenceBuild) ...[
                  TextFormField(
                    controller: _promptTextController,
                    decoration: _decoration('Prompt text'),
                    validator: (v) => _requiredTextValidator(v, 'Enter prompt text'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _optionsWordsController,
                    maxLines: 3,
                    decoration: _decoration('Options words (comma separated)'),
                    validator: (v) => _wordsValidator(v, 'Enter options'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _correctWordsController,
                    maxLines: 2,
                    decoration: _decoration('Correct words (comma separated)'),
                    validator: (v) => _wordsValidator(v, 'Enter correct words'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_type == audioDictation) ...[
                  TextFormField(
                    controller: _audioUrlController,
                    decoration: _decoration('Audio URL'),
                    validator: (v) => _requiredTextValidator(v, 'Enter audio URL'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _uploadingAudio ? null : _pickAndUploadAudio,
                      icon: _uploadingAudio
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.audiotrack_rounded),
                      label: Text(_uploadingAudio ? 'Uploading audio...' : 'Choose audio file'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _audioTextController,
                    maxLines: 3,
                    decoration: _decoration('Audio text'),
                    validator: (v) => _requiredTextValidator(v, 'Enter audio text'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_type == audioTranslate) ...[
                  TextFormField(
                    controller: _audioUrlController,
                    decoration: _decoration('Audio URL'),
                    validator: (v) => _requiredTextValidator(v, 'Enter audio URL'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _uploadingAudio ? null : _pickAndUploadAudio,
                      icon: _uploadingAudio
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.audiotrack_rounded),
                      label: Text(_uploadingAudio ? 'Uploading audio...' : 'Choose audio file'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _translateTextController,
                    maxLines: 3,
                    decoration: _decoration('Translate text'),
                    validator: (v) => _requiredTextValidator(v, 'Enter translation text'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_type == wordMatch) ...[
                  TextFormField(
                    controller: _matchingPairsController,
                    maxLines: 5,
                    decoration: _decoration('Matching pairs: cat|мысық, house|үй'),
                    validator: _matchingPairsValidator,
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Write one pair per line: left|right',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _xpRewardController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('XP reward'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter XP';
                    if (int.tryParse(v.trim()) == null) return 'Enter a number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _orderIndexController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Order index'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter order';
                    if (int.tryParse(v.trim()) == null) return 'Enter a number';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEdit ? 'Save' : 'Add'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: purple,
                      side: const BorderSide(color: purple, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F4FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
