import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/task_model.dart';
import 'package:kazakh_learning_app/services/lesson_service.dart';

class ExerciseWordOrderScreen extends StatefulWidget {
  final int lessonId;

  const ExerciseWordOrderScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<ExerciseWordOrderScreen> createState() =>
      _ExerciseWordOrderScreenState();
}

enum _Stage { building, correct, wrong }

class _ExerciseWordOrderScreenState extends State<ExerciseWordOrderScreen> {
  static const green = Color(0xFF58CC02);
  static const red = Color(0xFFFF4B4B);
  static const blue = Color(0xFF6A00FF);

  final LessonService _service = LessonService();

  List<TaskModel> tasks = [];
  int currentIndex = 0;
  int lives = 3;

  List<String> correctAnswer = [];
  List<String> slots = [];
  List<String> bank = [];

  _Stage stage = _Stage.building;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  List<String> _cleanWords(List<String> words) {
    return words
        .expand((item) => item.replaceAll(',', ' ').split(RegExp(r'\s+')))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _loadTasks() async {
    final data = await _service.getLessonTasks(widget.lessonId);

    if (!mounted) return;

    setState(() {
      tasks = data;
      if (tasks.isNotEmpty) _setupTask(tasks.first);
    });
  }

  void _setupTask(TaskModel task) {
    correctAnswer = _cleanWords(task.correctWords);
    bank = List.from(_cleanWords(task.optionsWords));
    slots = [];
    stage = _Stage.building;
  }

  void _placeWord(int i) {
    if (stage != _Stage.building) return;
    setState(() {
      slots.add(bank[i]);
      bank.removeAt(i);
    });
  }

  void _removeWord(int i) {
    if (stage != _Stage.building) return;
    setState(() {
      bank.add(slots[i]);
      slots.removeAt(i);
    });
  }

  void _check() {
    final ok = _equals(slots, correctAnswer);

    if (ok) {
      setState(() => stage = _Stage.correct);
    } else {
      setState(() {
        lives--;
        stage = _Stage.wrong;
      });
    }
  }

  void _continue() {
    if (currentIndex < tasks.length - 1) {
      setState(() {
        currentIndex++;
        _setupTask(tasks[currentIndex]);
      });
    } else {
      Navigator.pop(context);
    }
  }

  bool _equals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final task = tasks[currentIndex];

    return Scaffold(
      body: Stack(
        children: [
          /// 🔥 ОСНОВНОЙ ЭКРАН
          Column(
            children: [
              Container(
                height: 110,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF7B1FA2),
                      Color(0xFF9C27B0),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            '$lives',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        icon:
                        const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TRANSLATE THIS SENTENCE",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(task.promptText),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Wrap(
                            spacing: 8,
                            children: List.generate(slots.length, (i) {
                              return GestureDetector(
                                onTap: () => _removeWord(i),
                                child: Chip(label: Text(slots[i])),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(bank.length, (i) {
                            return GestureDetector(
                              onTap: () => _placeWord(i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(color: blue),
                                ),
                                child: Text(bank[i]),
                              ),
                            );
                          }),
                        ),

                        const Spacer(),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _check,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                            ),
                            child: const Text("CHECKKKKK"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// 🎉 SUCCESS ЭКРАН
          if (stage == _Stage.correct)
            Container(
              color: const Color(0xFF6A00FF),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/Oyu.png', height: 120),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("You did great job"),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("+20 XP"),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _continue,
                      child: const Text("Get"),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}