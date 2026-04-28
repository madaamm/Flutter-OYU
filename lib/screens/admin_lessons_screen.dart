import 'dart:math' as math;
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
  static const Color lightBg = Color(0xFFFFFFFF);

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

  void _openLessonSheet(LessonModel lesson) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AdminLessonActionSheet(
          title: lesson.title,
          level: lesson.level,
          isArchived: lesson.isArchived,
          onEditTap: () {
            Navigator.pop(context);
            _openEditDialog(lesson);
          },
          onArchiveTap: () {
            Navigator.pop(context);
            _toggleArchive(lesson);
          },
        );
      },
    );
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
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEDE2FF),
                      foregroundColor: purple,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.archive_outlined, size: 22),
                    label: const Text(
                      'Архив',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _openAddDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F00A8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 26),
                    label: const Text(
                      'Добавить',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(26, 0, 26, 0),
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
                                        style:
                                        const TextStyle(color: Colors.grey),
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

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 30, 16, 50),
                        itemCount: (lessons.length / 6).ceil(),
                        itemBuilder: (context, groupIndex) {
                          final start = groupIndex * 6;
                          final end = math.min(start + 6, lessons.length);
                          final groupLessons = lessons.sublist(start, end);

                          return _AdminLessonCircleGroup(
                            lessons: groupLessons,
                            startNumber: start + 1,
                            mascotSleeping: groupIndex.isOdd,
                            onTapLesson: _openLessonSheet,
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

class _AdminLessonCircleGroup extends StatelessWidget {
  final List<LessonModel> lessons;
  final int startNumber;
  final bool mascotSleeping;
  final void Function(LessonModel lesson) onTapLesson;

  const _AdminLessonCircleGroup({
    required this.lessons,
    required this.startNumber,
    required this.mascotSleeping,
    required this.onTapLesson,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: lessons.length == 6 ? 610 : 535,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final centerX = width / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 118,
                left: centerX - 110,
                child: Image.asset(
                  mascotSleeping
                      ? 'assets/images/Oyu_uyktauda.png'
                      : 'assets/images/Oyu.png',
                  width: 220,
                  fit: BoxFit.contain,
                ),
              ),

              for (int i = 0; i < lessons.length && i < 6; i++)
                _lessonPosition(
                  lesson: lessons[i],
                  number: startNumber + i,
                  index: i,
                  centerX: centerX,
                ),

              if (lessons.length == 6)
                Positioned(
                  top: 455,
                  left: centerX - 43,
                  child: const _ChestButton(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _lessonPosition({
    required LessonModel lesson,
    required int number,
    required int index,
    required double centerX,
  }) {
    final positions = [
      Offset(centerX - 38, 10),   // 1
      Offset(centerX - 180, 120), // 2
      Offset(centerX + 104, 120), // 3
      Offset(centerX - 180, 285), // 4
      Offset(centerX + 104, 285), // 5
      Offset(centerX - 38, 395),  // 6
    ];

    final pos = positions[index];

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onTap: () => onTapLesson(lesson),
        child: _LessonCircle(
          number: number,
          isArchived: lesson.isArchived,
        ),
      ),
    );
  }
}

class _LessonCircle extends StatelessWidget {
  final int number;
  final bool isArchived;

  const _LessonCircle({
    required this.number,
    required this.isArchived,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isArchived ? 0.45 : 1,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isArchived
              ? const LinearGradient(
            colors: [
              Color(0xFFE8E8E8),
              Color(0xFFBEBEBE),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [
              Color(0xFF9B19E6),
              Color(0xFF4B008C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 6,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 10,
              left: 13,
              child: Container(
                width: 27,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Color(0xFFFF8BFF),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChestButton extends StatelessWidget {
  const _ChestButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF8C12D9),
            Color(0xFF39006E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 7,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/images/Sandyk.png',
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _AdminLessonActionSheet extends StatelessWidget {
  final String title;
  final String level;
  final bool isArchived;
  final VoidCallback onEditTap;
  final VoidCallback onArchiveTap;

  const _AdminLessonActionSheet({
    required this.title,
    required this.level,
    required this.isArchived,
    required this.onEditTap,
    required this.onArchiveTap,
  });

  static const Color purple = Color(0xFF7B1FE0);
  static const Color darkPurple = Color(0xFF5A0FAE);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [purple, darkPurple],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: purple.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (level.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  level,
                  style: const TextStyle(
                    color: Color(0xFFEBD9FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _PopupButton(
                text: 'Өзгерту',
                textColor: purple,
                onTap: onEditTap,
              ),
              const SizedBox(height: 14),
              _PopupButton(
                text: isArchived ? 'Разархивировать' : 'Архивировать',
                textColor: const Color(0xFFFFC400),
                onTap: onArchiveTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopupButton extends StatelessWidget {
  final String text;
  final Color textColor;
  final VoidCallback onTap;

  const _PopupButton({
    required this.text,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
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