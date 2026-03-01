import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/screens/scenario_select_screen.dart';
import 'package:kazakh_learning_app/screens/auth_screen.dart';

class ConfirmEmailScreen extends StatefulWidget {
  final String email;

  const ConfirmEmailScreen({super.key, required this.email});

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  static const Color purple = Color(0xFF8E5BFF);

  final _codeController = TextEditingController();
  bool isLoading = false;
  String? errorText;

  Future<void> _confirmEmail() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() => errorText = "Кодты енгізіңіз");
      return;
    }

    setState(() {
      isLoading = true;
      errorText = null;
    });

    final url =
    Uri.parse('https://oyu-learnkz.onrender.com/api/auth/confirm-email');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"token": code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email сәтті расталды 🎉")),
        );

        // ✅ 1 рет қана көрсету логикасы
        final auth = AuthService();
        final wasShown = await auth.isScenarioShownForEmail(widget.email);

        if (!mounted) return;

        if (!wasShown) {
          await auth.setScenarioShownForEmail(widget.email, true);

          final userName = widget.email.split('@').first;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ScenarioSelectScreen(userName: userName),
            ),
          );
        } else {
          // Бұрын көрсетілген болса → қайта көрсетпейміз
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          );
        }
      } else {
        setState(() {
          errorText = data['message'] ?? "Қате код";
        });
      }
    } catch (e) {
      setState(() {
        errorText = "Server error";
      });
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
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
                child: const Center(
                  child: Text(
                    'Confirm Email',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Код жіберілді:",
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // INPUT
                    TextField(
                      controller: _codeController,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: "Кодты енгізіңіз",
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: errorText != null
                                ? Colors.redAccent
                                : Colors.black26,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: errorText != null
                                ? Colors.redAccent
                                : purple,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),

                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _confirmEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          "Confirm",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}