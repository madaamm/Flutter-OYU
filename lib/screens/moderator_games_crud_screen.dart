import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameCategory { speaking, reading, listening, writing }

extension GameCategoryX on GameCategory {
  String get label {
    switch (this) {
      case GameCategory.speaking:
        return 'Speaking';
      case GameCategory.reading:
        return 'Reading';
      case GameCategory.listening:
        return 'Listening';
      case GameCategory.writing:
        return 'Writing';
    }
  }

  String get defaultSubtitle {
    switch (this) {
      case GameCategory.speaking:
        return 'Practice pronunciation';
      case GameCategory.reading:
        return 'Match words with images';
      case GameCategory.listening:
        return 'Identify correct words';
      case GameCategory.writing:
        return 'Type and trace letters';
    }
  }

  _CatUI get ui {
    switch (this) {
      case GameCategory.speaking:
        return const _CatUI(
          icon: Icons.mic_none,
          iconBg: Color(0xFFFF4D4D),
          border: Color(0xFFFFB3B3),
        );
      case GameCategory.reading:
        return const _CatUI(
          icon: Icons.menu_book_outlined,
          iconBg: Color(0xFF2F80FF),
          border: Color(0xFFBBD7FF),
        );
      case GameCategory.listening:
        return const _CatUI(
          icon: Icons.headphones_outlined,
          iconBg: Color(0xFF00C853),
          border: Color(0xFFB6F2C8),
        );
      case GameCategory.writing:
        return const _CatUI(
          icon: Icons.edit_outlined,
          iconBg: Color(0xFF8E5BFF),
          border: Color(0xFFD9C9FF),
        );
    }
  }
}

class _CatUI {
  final IconData icon;
  final Color iconBg;
  final Color border;
  const _CatUI({required this.icon, required this.iconBg, required this.border});
}

class GameTask {
  final String id;
  final String title;
  final String subtitle;

  GameTask({required this.id, required this.title, required this.subtitle});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
  };

  factory GameTask.fromJson(Map<String, dynamic> j) {
    return GameTask(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      subtitle: (j['subtitle'] ?? '—').toString(),
    );
  }
}

/// ✅ Start осы экранды ашады: SharedPreferences-тен category tasks-ты өзі оқиды/сақтайды
class ModeratorCategoryTasksEntryScreen extends StatefulWidget {
  final GameCategory category;
  const ModeratorCategoryTasksEntryScreen({super.key, required this.category});

  @override
  State<ModeratorCategoryTasksEntryScreen> createState() =>
      _ModeratorCategoryTasksEntryScreenState();
}

class _ModeratorCategoryTasksEntryScreenState
    extends State<ModeratorCategoryTasksEntryScreen> {
  static const Color bg = Color(0xFFF6F1FF);
  static const String _storageKey = 'mod_games_by_category_v2_simple';

  bool loading = true;
  late Map<GameCategory, List<GameTask>> data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      data = {
        GameCategory.speaking: [],
        GameCategory.reading: [],
        GameCategory.listening: [],
        GameCategory.writing: [],
      };
      await _save();
    } else {
      data = _decode(raw);
      for (final c in GameCategory.values) {
        data.putIfAbsent(c, () => <GameTask>[]);
      }
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_encode(data)));
  }

  Map<String, dynamic> _encode(Map<GameCategory, List<GameTask>> src) {
    final out = <String, dynamic>{};
    for (final entry in src.entries) {
      out[entry.key.name] = entry.value.map((e) => e.toJson()).toList();
    }
    return out;
  }

  Map<GameCategory, List<GameTask>> _decode(String raw) {
    final decoded = jsonDecode(raw);
    final out = <GameCategory, List<GameTask>>{};
    if (decoded is Map) {
      for (final c in GameCategory.values) {
        final listRaw = decoded[c.name];
        final list = <GameTask>[];
        if (listRaw is List) {
          for (final it in listRaw) {
            if (it is Map) list.add(GameTask.fromJson(it.cast<String, dynamic>()));
          }
        }
        out[c] = list;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final initial = List<GameTask>.from(data[widget.category] ?? const []);

    return ModeratorCategoryTasksScreen(
      category: widget.category,
      initial: initial,
      onSave: (updated) async {
        setState(() => data[widget.category] = updated);
        await _save();
      },
    );
  }
}

/// ✅ Ішінде тек: Add task + Edit/Delete + Title/Subtitle bottom sheet
class ModeratorCategoryTasksScreen extends StatefulWidget {
  final GameCategory category;
  final List<GameTask> initial;
  final Future<void> Function(List<GameTask> updated) onSave;

  const ModeratorCategoryTasksScreen({
    super.key,
    required this.category,
    required this.initial,
    required this.onSave,
  });

  @override
  State<ModeratorCategoryTasksScreen> createState() =>
      _ModeratorCategoryTasksScreenState();
}

class _ModeratorCategoryTasksScreenState
    extends State<ModeratorCategoryTasksScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  late List<GameTask> tasks;

  @override
  void initState() {
    super.initState();
    tasks = List<GameTask>.from(widget.initial);
  }

  Future<void> _addOrEdit({GameTask? existing}) async {
    final result = await showModalBottomSheet<GameTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskEditorSheet(
        category: widget.category,
        task: existing,
      ),
    );

    if (result == null) return;

    setState(() {
      if (existing == null) {
        tasks.insert(0, result);
      } else {
        final idx = tasks.indexWhere((t) => t.id == existing.id);
        if (idx != -1) tasks[idx] = result;
      }
    });

    await widget.onSave(tasks);
  }

  Future<void> _delete(GameTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Өшіру?'),
        content: Text('“${task.title}” тапсырмасын өшірейік пе?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Жоқ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Иә')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => tasks.removeWhere((t) => t.id == task.id));
    await widget.onSave(tasks);
  }

  @override
  Widget build(BuildContext context) {
    final ui = widget.category.ui;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: purple,
        title: Text('${widget.category.label} tasks'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: ui.iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(ui.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.category.label} tasks',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _addOrEdit(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      'Add task',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            const _EmptyHint(text: 'Әзірге тапсырма жоқ. Add task арқылы қос.'),
          for (final t in tasks) ...[
            _TaskCardSimple(
              category: widget.category,
              task: t,
              onEdit: () => _addOrEdit(existing: t),
              onDelete: () => _delete(t),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _TaskCardSimple extends StatelessWidget {
  final GameCategory category;
  final GameTask task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCardSimple({
    required this.category,
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ui = category.ui;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ui.border.withOpacity(0.55), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: ui.iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(ui.icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(task.subtitle, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Text(text, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
    );
  }
}

class _TaskEditorSheet extends StatefulWidget {
  final GameCategory category;
  final GameTask? task;

  const _TaskEditorSheet({
    required this.category,
    this.task,
  });

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  static const Color purple = Color(0xFF8E5BFF);

  late final TextEditingController title;
  late final TextEditingController subtitle;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.task?.title ?? widget.category.label);
    subtitle = TextEditingController(text: widget.task?.subtitle ?? widget.category.defaultSubtitle);
  }

  @override
  void dispose() {
    title.dispose();
    subtitle.dispose();
    super.dispose();
  }

  void _submit() {
    final t = title.text.trim();
    final s = subtitle.text.trim();
    if (t.isEmpty) return;

    Navigator.pop(
      context,
      GameTask(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: t,
        subtitle: s.isEmpty ? '—' : s,
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
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 14),
            Text(
              widget.task == null ? 'Add task • ${widget.category.label}' : 'Edit task • ${widget.category.label}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            TextField(controller: subtitle, decoration: const InputDecoration(labelText: 'Subtitle')),
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}