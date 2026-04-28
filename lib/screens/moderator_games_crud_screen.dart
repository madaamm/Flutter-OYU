import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'moderator_books_screen.dart';


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
}

class GameTask {
  final String id;
  final String title;
  final String subtitle;

  GameTask({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

// ================= ENTRY SCREEN =================

class ModeratorCategoryTasksEntryScreen extends StatelessWidget {
  final GameCategory category;

  const ModeratorCategoryTasksEntryScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    if (category == GameCategory.reading) {
      return const ModeratorBooksScreen();
    }

    if (category == GameCategory.speaking) {
      return const Scaffold(
        body: Center(
          child: Text('Speaking screen coming soon'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(category.label),
      ),
      body: const Center(
        child: Text('Coming soon'),
      ),
    );
  }
}