import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/screens/home_screen.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/services/language_service.dart';

class InitialSetupScreen extends StatefulWidget {
  final String userName;

  const InitialSetupScreen({
    super.key,
    required this.userName,
  });

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

enum _SetupStep {
  loading,
  language,
  levelChoice,
  placementTest,
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color deepPurple = Color(0xFF6D2DFF);

  final _auth = AuthService();
  final _languageService = LanguageService();

  _SetupStep _step = _SetupStep.loading;
  bool _busy = false;

  String? _selectedLanguage;
  List<Map<String, dynamic>> _questions = const [];
  final Map<int, String> _answers = {};
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _auth.getInitialSetupStatus();
      final language = (status['interfaceLanguage'] ?? '').toString();
      final completed = status['initialSetupCompleted'] == true;

      if (language.isNotEmpty) {
        await _languageService.setLanguage(language);
      }

      if (!mounted) return;

      setState(() {
        _selectedLanguage = language.isEmpty ? null : language;

        if (completed && language.isNotEmpty) {
          _step = _SetupStep.levelChoice;
        } else if (language.isEmpty) {
          _step = _SetupStep.language;
        } else {
          _step = _SetupStep.levelChoice;
        }
      });

      if (completed && language.isNotEmpty && mounted) {
        _goHome();
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
      setState(() => _step = _SetupStep.language);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeScreen(userName: widget.userName),
      ),
      (route) => false,
    );
  }

  Future<void> _saveLanguage(String language) async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await _auth.saveInterfaceLanguage(language);
      await _languageService.setLanguage(language);

      if (!mounted) return;

      setState(() {
        _selectedLanguage = language;
        _step = _SetupStep.levelChoice;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startFromZero() async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await _auth.startFromZero();
      if (!mounted) return;
      _goHome();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPlacementTest() async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      final data = await _auth.getPlacementTestQuestions();
      final questionsRaw = data['questions'];
      final questions = questionsRaw is List
          ? questionsRaw.whereType<Map>().map((item) {
              return item.map(
                (key, value) => MapEntry(key.toString(), value),
              );
            }).toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _answers.clear();
        _currentQuestionIndex = 0;
        _step = _SetupStep.placementTest;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitPlacementTest() async {
    if (_busy || _questions.isEmpty) return;

    if (_answers.length != _questions.length) {
      _showMessage('Please answer all questions first.');
      return;
    }

    setState(() => _busy = true);
    try {
      final payload = _answers.entries
          .map(
            (entry) => {
              'questionId': entry.key,
              'selectedOption': entry.value,
            },
          )
          .toList();

      final result = await _auth.submitPlacementTest(payload);
      final level = (result['level'] ?? 'A0').toString();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Your level is set'),
            content: Text('You have been assigned level $level.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      _goHome();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 170,
              decoration: const BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Qoshqar.png',
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'OYU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: _buildContent(),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _SetupStep.loading:
        return const Center(child: CircularProgressIndicator(color: purple));
      case _SetupStep.language:
        return _buildLanguageStep();
      case _SetupStep.levelChoice:
        return _buildLevelChoiceStep();
      case _SetupStep.placementTest:
        return _buildPlacementTestStep();
    }
  }

  Widget _buildLanguageStep() {
    const languages = [
      {'code': 'ru', 'title': 'Русский', 'subtitle': 'Russian interface'},
      {'code': 'en', 'title': 'English', 'subtitle': 'English interface'},
      {'code': 'kz', 'title': 'Qazaqsha', 'subtitle': 'Kazakh interface'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your interface language',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'You can change it later in the app settings.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: languages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = languages[index];
              final code = item['code']!;
              final selected = _selectedLanguage == code;

              return InkWell(
                onTap: _busy ? null : () => _saveLanguage(code),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFF0E8FF) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? deepPurple : const Color(0xFFE1D8F5),
                      width: selected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F1FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.language, color: deepPurple),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['subtitle']!,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_busy && selected)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: deepPurple,
                          ),
                        )
                      else if (selected)
                        const Icon(Icons.check_circle, color: deepPurple),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLevelChoiceStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose how to start learning',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can take a quick test or start from the very beginning with level A0.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          _choiceCard(
            icon: Icons.quiz_outlined,
            title: 'Test for my level',
            subtitle:
                'After the test, lessons up to your level will become available.',
            actionLabel: 'Start test',
            onTap: _openPlacementTest,
          ),
          const SizedBox(height: 16),
          _choiceCard(
            icon: Icons.flag_outlined,
            title: 'Start from zero (A0)',
            subtitle:
                'You will begin from the first 6 lessons for complete beginners.',
            actionLabel: 'Start with A0',
            onTap: _startFromZero,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _choiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5DCF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E8FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: deepPurple),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _busy ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      actionLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementTestStep() {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: purple));
    }

    final question = _questions[_currentQuestionIndex];
    final questionId = (question['id'] as num?)?.toInt() ?? 0;
    final options = (question['options'] as List?)?.cast<String>() ?? const [];
    final selectedOption = _answers[questionId];
    final isLast = _currentQuestionIndex == _questions.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _busy
                  ? null
                  : () {
                      setState(() => _step = _SetupStep.levelChoice);
                    },
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE6E0F3),
                  valueColor: const AlwaysStoppedAnimation<Color>(deepPurple),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
          style: const TextStyle(
            color: Colors.black45,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          (question['question'] ?? '').toString(),
          style: const TextStyle(
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final optionText = options[index];
              final optionKey = optionText.substring(0, 1);
              final selected = selectedOption == optionKey;

              return InkWell(
                onTap: _busy
                    ? null
                    : () {
                        setState(() {
                          _answers[questionId] = optionKey;
                        });
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFF0E8FF) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? deepPurple : const Color(0xFFE3DCF6),
                      width: selected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          optionText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: deepPurple),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: selectedOption == null || _busy
                ? null
                : () {
                    if (isLast) {
                      _submitPlacementTest();
                      return;
                    }

                    setState(() => _currentQuestionIndex += 1);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: deepPurple,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE6DFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isLast ? 'Finish test' : 'Next question',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}



