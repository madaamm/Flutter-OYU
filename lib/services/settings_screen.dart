import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/services/language_service.dart';

import '../screens/welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langService = LanguageService();
    return Scaffold(
      appBar: AppBar(title: const Text('Language / Тіл')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Русский'),
            trailing: langService.currentLanguage == 'ru' ? const Icon(Icons.check) : null,
            onTap: () async {
              await langService.setLanguage('ru');
              _restartApp(context);
            },
          ),
          ListTile(
            title: const Text('English'),
            trailing: langService.currentLanguage == 'en' ? const Icon(Icons.check) : null,
            onTap: () async {
              await langService.setLanguage('en');
              _restartApp(context);
            },
          ),
          ListTile(
            title: const Text('Қазақша'),
            trailing: langService.currentLanguage == 'kz' ? const Icon(Icons.check) : null,
            onTap: () async {
              await langService.setLanguage('kz');
              _restartApp(context);
            },
          ),
        ],
      ),
    );
  }

  void _restartApp(BuildContext context) {
    // Возвращаемся на главный экран и перезагружаем приложение
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
    );
  }
}