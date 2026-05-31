import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _prefKey = 'app_language';
  static const String defaultLanguage = 'ru'; // ru, en, kz

  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  String _currentLanguage = defaultLanguage;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_prefKey) ?? defaultLanguage;
  }

  String get currentLanguage => _currentLanguage;

  Future<void> setLanguage(String lang) async {
    if (lang == _currentLanguage) return;
    _currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang);
  }
}