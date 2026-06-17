import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/l10n/app_text.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const purple = Color(0xFF8E5BFF);

  final _tokenC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _hidePass = true;
  bool _hideConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _tokenC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();

    final token = _tokenC.text.trim();
    final pass = _passC.text.trim();
    final confirm = _confirmC.text.trim();

    if (token.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _show(context.tr('fill_all_fields'));
      return;
    }
    if (pass != confirm) {
      _show(context.tr('passwords_not_match'));
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('https://learnkz.kazi.rocks/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'newPassword': pass,
          'repeatPassword': confirm,
        }),
      );

      final data = _tryJson(res.body);

      if (res.statusCode == 200) {
        _show((data['message'] ?? context.tr('password_changed')).toString());
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _show((data['message'] ?? context.tr('reset_failed')).toString());
      }
    } catch (_) {
      _show(context.tr('server_error'));
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

  InputDecoration _inputDec({
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.black38,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: purple, width: 1.6),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        height: 48,
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
              const SizedBox(height: 24),
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
                    Text(
                      context.tr('change_new_password'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('enter_code_new_password'),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      context.tr('code_token_email'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tokenC,
                      decoration: _inputDec(hint: context.tr('example_code')),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('new_password'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passC,
                      obscureText: _hidePass,
                      decoration: _inputDec(
                        hint: '••••••••',
                        suffix: IconButton(
                          icon: Icon(
                            _hidePass ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _hidePass = !_hidePass),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('confirm_password_short'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmC,
                      obscureText: _hideConfirm,
                      decoration: _inputDec(
                        hint: '••••••••',
                        suffix: IconButton(
                          icon: Icon(
                            _hideConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _hideConfirm = !_hideConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _reset,
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
                            : Text(
                                context.tr('reset_password'),
                                style: const TextStyle(
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
