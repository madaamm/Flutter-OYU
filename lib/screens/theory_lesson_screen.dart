import 'package:flutter/material.dart';

class TheoryLessonScreen extends StatelessWidget {
  final int lessonNumber;
  final String level;

  const TheoryLessonScreen({
    super.key,
    required this.lessonNumber,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6A00FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        title: Text("Theory Lesson $lessonNumber Level $level"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Word Order: SOV (Subject-Object-Verb)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Unlike English (SVO), Kazakh puts the verb at the end:\n\n"
                        "English: I drink water.\n\n"
                        "Kazakh: Men (I) + su (water) + ishemin (drink).\n"
                        "→ Men su ishemin.",
                    style: TextStyle(height: 1.45),
                  ),
                  SizedBox(height: 16),

                  Text(
                    "No Gender, No Articles",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text("• No \"he/she\" distinction: ол = he/she/it"),
                  SizedBox(height: 6),
                  Text("• No \"a/an/the\": kitap = a book / the book"),
                  SizedBox(height: 16),

                  Text(
                    "Plurals: Add -лар / -лер",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text("dost (friend) → dosttar (friends)"),
                  SizedBox(height: 6),
                  Text("ül (student) → ülder (students)"),
                  SizedBox(height: 10),
                  Text("(Choose -tar/-ter based on vowel harmony)"),
                  SizedBox(height: 18),

                  _CaseTable(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseTable extends StatelessWidget {
  const _CaseTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: const [
          _RowItem(left: "Case", right: "Ending", header: true),
          Divider(height: 1),
          _RowItem(left: "Nominative", right: "—"),
          Divider(height: 1),
          _RowItem(left: "Dative", right: "-ға/-ге"),
          Divider(height: 1),
          _RowItem(left: "Accusative", right: "-ды/-ді"),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String left;
  final String right;
  final bool header;

  const _RowItem({required this.left, required this.right, this.header = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: header ? FontWeight.w900 : FontWeight.w700,
      color: header ? Colors.black87 : Colors.black54,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(left, style: style)),
          Expanded(child: Text(right, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}