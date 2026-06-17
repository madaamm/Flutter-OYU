import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/services/language_service.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService(),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const WelcomeScreen(),
          builder: (context, child) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child!,
            );
          },
        );
      },
    );
  }
}
