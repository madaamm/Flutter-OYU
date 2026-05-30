import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:kazakh_learning_app/screens/reset_success_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color purple = Color(0xFF8E5BFF);

  final _emailC = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _emailC.text.trim();

    if (email.isEmpty) {
      _show('Enter your email.');
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('https://learnkz.kazi.rocks/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = _tryJson(res.body);

      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetSuccessScreen(email: email),
          ),
        );
      } else {
        _show((data['message'] ?? 'Request failed').toString());
      }
    } catch (e) {
      _show('Server error');
    }

    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic> _tryJson(String body) {
    try {
      final x = jsonDecode(body);
      return (x is Map<String, dynamic>) ? x : {};
    } catch (_) {
      return {};
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
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

              // CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Forget Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter your registered email below',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Email address',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'example@gmail.com',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F1F1),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: purple, width: 1.6),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Text(
                          'Remember the password?',
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              color: purple,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
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