import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/lesson_model.dart';
import 'package:kazakh_learning_app/services/admin_lesson_service.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  static const Color purple = Color(0xFF5B18D6);
  static const Color lightBg = Color(0xFFF1F1F1);

  final AdminLessonService _service = AdminLessonService();
  late Future<List<LessonModel>> _futureLessons;

  @override
  void initState() {
    super.initState();
    _futureLessons = _service.getAdminLessons();
  }

  Future<void> _reload() async {
    setState(() {
      _futureLessons = _service.getAdminLessons();
    });
    await _futureLessons;
  }

  Future<void> _openAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _LessonDialog(),
    );

    if (result == true) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Урок backend-ке сәтті сақталды')),
      );
    }
  }

  Future<void> _openEditDialog(LessonModel lesson) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _LessonDialog(lesson: lesson),
    );

    if (result == true) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Урок сәтті жаңартылды')),
      );
    }
  }

  Future<void> _toggleArchive(LessonModel lesson) async {
    try {
      await _service.archiveLesson(
        lessonId: lesson.id,
        isArchived: !lesson.isArchived,
      );

      await _reload();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lesson.isArchived
                ? 'Урок разархивирован'
                : 'Урок архивке жіберілді',
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
                  const Expanded(
                    child: Text(
                      'Уроктар',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
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
                  child: FutureBuilder<List<LessonModel>>(
                    future: _futureLessons,
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
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.cloud_off_rounded,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'Уроктар жүктелмеді',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: purple,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${snapshot.error}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 18),
                                      ElevatedButton(
                                        onPressed: _reload,
                                        child: const Text('Қайта көру'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      final lessons = snapshot.data ?? [];

                      if (lessons.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 650,
                              child: Center(
                                child: Text(
                                  'Әзірге урок жоқ',
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
                        itemCount: lessons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final lesson = lessons[index];
                          return _AdminLessonCard(
                            lesson: lesson,
                            onEdit: () => _openEditDialog(lesson),
                            onArchive: () => _toggleArchive(lesson),
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

class _AdminLessonCard extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _AdminLessonCard({
    required this.lesson,
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
          color: lesson.isArchived
              ? const Color(0xFFD3D3D3)
              : const Color(0xFFE7D8FF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: lesson.isArchived
                  ? const LinearGradient(
                colors: [Color(0xFFDADADA), Color(0xFFBEBEBE)],
              )
                  : const LinearGradient(
                colors: [Color(0xFF8E2BFF), Color(0xFF4E0497)],
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Image(
                image: AssetImage('assets/images/Pink_egg.png'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: lesson.isArchived ? Colors.grey : purple,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lesson.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                if (lesson.lectureText.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    lesson.lectureText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(text: lesson.level.isEmpty ? '—' : lesson.level),
                    _Tag(text: 'Order: ${lesson.orderIndex}'),
                    _Tag(text: lesson.isArchived ? 'Archived' : 'Active'),
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
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Өзгерту'),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(
                  lesson.isArchived ? 'Разархивировать' : 'Архивировать',
                ),
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

class _LessonDialog extends StatefulWidget {
  final LessonModel? lesson;

  const _LessonDialog({this.lesson});

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  static const Color purple = Color(0xFF5B18D6);

  final _formKey = GlobalKey<FormState>();
  final _service = AdminLessonService();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _lectureTextController;
  late final TextEditingController _orderController;

  String _level = 'A0';
  bool _saving = false;

  bool get isEdit => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.lesson?.description ?? '',
    );
    _lectureTextController = TextEditingController(
      text: widget.lesson?.lectureText ?? '',
    );
    _orderController = TextEditingController(
      text: (widget.lesson?.orderIndex ?? 0).toString(),
    );
    _level = widget.lesson?.level.isNotEmpty == true
        ? widget.lesson!.level
        : 'A0';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _lectureTextController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final lectureText = _lectureTextController.text.trim();
      final orderIndex = int.parse(_orderController.text.trim());

      if (isEdit) {
        await _service.updateLesson(
          lessonId: widget.lesson!.id,
          title: title,
          description: description,
          lectureText: lectureText,
          level: _level,
          orderIndex: orderIndex,
        );
      } else {
        await _service.createLesson(
          title: title,
          description: description,
          lectureText: lectureText,
          level: _level,
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
                  isEdit ? 'Урокты өзгерту' : 'Жаңа урок қосу',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  decoration: _decoration('Title'),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title енгіз' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _decoration('Description'),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Description енгіз'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lectureTextController,
                  decoration: _decoration('Theory / Lecture text'),
                  maxLines: 6,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Theory text енгіз'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _level,
                  decoration: _decoration('Level'),
                  items: const [
                    DropdownMenuItem(value: 'A0', child: Text('A0')),
                    DropdownMenuItem(value: 'A1', child: Text('A1')),
                    DropdownMenuItem(value: 'A2', child: Text('A2')),
                    DropdownMenuItem(value: 'B1', child: Text('B1')),
                    DropdownMenuItem(value: 'B2', child: Text('B2')),
                    DropdownMenuItem(value: 'C1', child: Text('C1')),
                    DropdownMenuItem(value: 'C2', child: Text('C2')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _level = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Order index'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Order енгіз';
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'Сан енгіз';
                    }
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