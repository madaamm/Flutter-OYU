import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/lesson_model.dart';
import 'package:kazakh_learning_app/models/task_model.dart';
import 'package:kazakh_learning_app/services/admin_task_service.dart';

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
        const SnackBar(content: Text('Тапсырма қосылды')),
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
        const SnackBar(content: Text('Тапсырма жаңартылды')),
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
          content: Text(
            task.isArchived
                ? 'Тапсырма разархивирован'
                : 'Тапсырма архивке жіберілді',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Добавить',
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
                                      const Icon(
                                        Icons.cloud_off_rounded,
                                        size: 58,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'Тапсырмалар жүктелмеді',
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
                                  'Әзірге тапсырма жоқ',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: task.isArchived
              ? const Color(0xFFD3D3D3)
              : const Color(0xFFE7D8FF),
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
              gradient: LinearGradient(
                colors: [Color(0xFF8E2BFF), Color(0xFF4E0497)],
              ),
            ),
            child: const Icon(
              Icons.extension_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.promptText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${task.promptLang} → ${task.targetLang}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(text: 'XP: ${task.xpReward}'),
                    _Tag(text: 'Order: ${task.orderIndex}'),
                    _Tag(text: 'Words: ${task.optionsWords.length}'),
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
              PopupMenuItem(
                value: 'edit',
                child: Text('Өзгерту'),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text('Архивировать'),
              ),
            ],
          ),
        ],
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

  final _formKey = GlobalKey<FormState>();
  final _service = AdminTaskService();

  late final TextEditingController _promptTextController;
  late final TextEditingController _optionsWordsController;
  late final TextEditingController _correctWordsController;
  late final TextEditingController _xpRewardController;
  late final TextEditingController _orderIndexController;

  String _promptLang = 'RU';
  String _targetLang = 'KZ';
  bool _saving = false;

  bool get isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _promptTextController =
        TextEditingController(text: widget.task?.promptText ?? '');
    _optionsWordsController = TextEditingController(
      text: widget.task?.optionsWords.join(', ') ?? '',
    );
    _correctWordsController = TextEditingController(
      text: widget.task?.correctWords.join(', ') ?? '',
    );
    _xpRewardController = TextEditingController(
      text: (widget.task?.xpReward ?? 10).toString(),
    );
    _orderIndexController = TextEditingController(
      text: (widget.task?.orderIndex ?? 1).toString(),
    );
    _promptLang = widget.task?.promptLang.isNotEmpty == true
        ? widget.task!.promptLang
        : 'RU';
    _targetLang = widget.task?.targetLang.isNotEmpty == true
        ? widget.task!.targetLang
        : 'KZ';
  }

  @override
  void dispose() {
    _promptTextController.dispose();
    _optionsWordsController.dispose();
    _correctWordsController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final promptText = _promptTextController.text.trim();
      final optionsWords = _splitWords(_optionsWordsController.text);
      final correctWords = _splitWords(_correctWordsController.text);
      final xpReward = int.parse(_xpRewardController.text.trim());
      final orderIndex = int.parse(_orderIndexController.text.trim());

      if (isEdit) {
        await _service.updateTask(
          taskId: widget.task!.id,
          promptLang: _promptLang,
          targetLang: _targetLang,
          promptText: promptText,
          optionsWords: optionsWords,
          correctWords: correctWords,
          xpReward: xpReward,
          orderIndex: orderIndex,
        );
      } else {
        await _service.createTask(
          lessonId: widget.lessonId,
          promptLang: _promptLang,
          targetLang: _targetLang,
          promptText: promptText,
          optionsWords: optionsWords,
          correctWords: correctWords,
          xpReward: xpReward,
          orderIndex: orderIndex,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қате: $e')),
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
                  isEdit ? 'Тапсырманы өзгерту' : 'Жаңа тапсырма қосу',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _promptLang,
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
                  value: _targetLang,
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
                TextFormField(
                  controller: _promptTextController,
                  decoration: _decoration('Prompt text'),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Prompt text енгіз' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _optionsWordsController,
                  maxLines: 3,
                  decoration:
                  _decoration('Options words (comma арқылы)'),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Options енгіз' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _correctWordsController,
                  maxLines: 2,
                  decoration:
                  _decoration('Correct words (comma арқылы)'),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Correct words енгіз' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _xpRewardController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('XP reward'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'XP енгіз';
                    if (int.tryParse(v.trim()) == null) return 'Сан енгіз';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _orderIndexController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Order index'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Order енгіз';
                    if (int.tryParse(v.trim()) == null) return 'Сан енгіз';
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
                        : Text(isEdit ? 'Сақтау' : 'Қосу'),
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