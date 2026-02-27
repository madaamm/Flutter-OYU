import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:kazakh_learning_app/screens/admin_home_screen.dart';
import 'package:kazakh_learning_app/screens/home_screen.dart'; // ✅ Вариант A
import 'package:kazakh_learning_app/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const Color purple = Color(0xFF8E5BFF);

  bool isLogin = true;
  bool isLoading = false;

  bool _hidePass = true;
  bool _hideConfirm = true;

  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passError;
  String? _confirmError;

  final _emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
  final _passRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>_\-\[\]\\\/~`+=;]).{8,}$',
  );

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  // ================= VALIDATION =================

  bool _isTitleCaseName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    final parts = trimmed.split(RegExp(r'\s+'));
    for (final p in parts) {
      if (p.isEmpty) continue;
      final first = p[0];
      if (first != first.toUpperCase()) return false;
    }
    return true;
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passError = null;
      _confirmError = null;
    });
  }

  bool _validateRegisterFields() {
    String? nameErr;
    String? emailErr;
    String? passErr;
    String? confirmErr;

    final name = _nameC.text.trim();
    final email = _emailC.text.trim();
    final pass = _passC.text.trim();
    final confirm = _confirmC.text.trim();

    if (name.isEmpty) {
      nameErr = 'Full name міндетті түрде толтырылуы керек';
    } else if (!_isTitleCaseName(name)) {
      nameErr = 'Атыңызды бас әріппен жазыңыз (мыс: Saltanat Nurbaeva)';
    }

    if (email.isEmpty) {
      emailErr = 'Email міндетті';
    } else if (!_emailRegex.hasMatch(email)) {
      emailErr = 'Email форматы дұрыс емес (мыс: example@mail.com)';
    }

    if (pass.isEmpty) {
      passErr = 'Құпиясөз міндетті';
    } else if (pass.length < 8) {
      passErr = 'Құпиясөз кемі 8 символ болуы керек';
    } else if (!_passRegex.hasMatch(pass)) {
      passErr = 'Құпиясөзде әріп, сан және символ болуы керек (мыс: Abc123!@)';
    }

    if (confirm.isEmpty) {
      confirmErr = 'Құпиясөзді қайта енгізіңіз';
    } else if (pass != confirm) {
      confirmErr = 'Құпиясөздер сәйкес келмейді';
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passError = passErr;
      _confirmError = confirmErr;
    });

    return nameErr == null &&
        emailErr == null &&
        passErr == null &&
        confirmErr == null;
  }

  bool _validateLoginFields() {
    String? emailErr;
    String? passErr;

    final email = _emailC.text.trim();
    final pass = _passC.text.trim();

    if (email.isEmpty) {
      emailErr = 'Email міндетті';
    } else if (!_emailRegex.hasMatch(email)) {
      emailErr = 'Email форматы дұрыс емес';
    }

    if (pass.isEmpty) {
      passErr = 'Құпиясөз міндетті';
    }

    setState(() {
      _emailError = emailErr;
      _passError = passErr;
      _nameError = null;
      _confirmError = null;
    });

    return emailErr == null && passErr == null;
  }

  // ================= BACKEND =================

  Future<void> _register() async {
    setState(() => isLoading = true);

    final url = Uri.parse('https://oyu-learnkz.onrender.com/api/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": _nameC.text.trim(),
          "email": _emailC.text.trim(),
          "password": _passC.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _login(afterRegister: true);
      } else {
        _showError(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _showError('Server error');
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _login({bool afterRegister = false}) async {
    setState(() => isLoading = true);

    final url = Uri.parse('https://oyu-learnkz.onrender.com/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _emailC.text.trim(),
          "password": _passC.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = (data['token'] ?? data['accessToken'] ?? '').toString();
        if (token.isEmpty) {
          _showError('Token келмеді (backend response тексер)');
          return;
        }

        await AuthService().saveToken(token);

        final user = (data['user'] is Map) ? data['user'] as Map : {};
        final role = (user['role'] ?? 'user').toString().trim().toLowerCase();
        await AuthService().saveRole(role);

        final userName = (user['username'] ??
            user['name'] ??
            _emailC.text.trim().split('@').first)
            .toString();

        if (!mounted) return;

        if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AdminHomeScreen(userName: userName),
            ),
          );
        } else {
          // ✅ ВАРИАНТ A: user -> HomeScreen (өз nav бар)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeScreen(userName: userName),
            ),
          );
        }
      } else {
        _showError(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showError('Server error');
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ================= UI ACTIONS =================

  void _switchTab(bool login) {
    setState(() {
      isLogin = login;
      isLoading = false;
      _hidePass = true;
      _hideConfirm = true;
    });
    _clearErrors();
  }

  void _onContinue() {
    FocusScope.of(context).unfocus();
    if (isLoading) return;

    if (isLogin) {
      final ok = _validateLoginFields();
      if (!ok) return;
      _login();
    } else {
      final ok = _validateRegisterFields();
      if (!ok) return;
      _register();
    }
  }

  // ================= UI BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // HEADER (OYU text + Qoshqar)
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

              const SizedBox(height: 14),

              // LOG IN / SIGN UP tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton(
                        title: 'log in',
                        active: isLogin,
                        onTap: () => _switchTab(true),
                      ),
                    ),
                    Expanded(
                      child: _tabButton(
                        title: 'Sign up',
                        active: !isLogin,
                        onTap: () => _switchTab(false),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // FORM CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    if (!isLogin) ...[
                      _label('Full name'),
                      _textField(
                        controller: _nameC,
                        hint: 'Your name',
                        errorText: _nameError,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _label('Your Email'),
                    _textField(
                      controller: _emailC,
                      hint: 'contact@dscodetech.com',
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _label('Password'),
                    _passwordField(
                      controller: _passC,
                      hint: '••••••••••••',
                      errorText: _passError,
                      obscure: _hidePass,
                      onToggle: () => setState(() => _hidePass = !_hidePass),
                    ),
                    if (isLogin) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _showError('Forgot password (кейін қосамыз)'),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: purple,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!isLogin) ...[
                      const SizedBox(height: 14),
                      _label('Repeat Password'),
                      _passwordField(
                        controller: _confirmC,
                        hint: '••••••••••••',
                        errorText: _confirmError,
                        obscure: _hideConfirm,
                        onToggle: () =>
                            setState(() => _hideConfirm = !_hideConfirm),
                      ),
                    ],

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
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
                            : Text(
                          isLogin ? 'Log in' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: const [
                        Expanded(
                          child: Divider(color: Colors.black12, thickness: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Or',
                            style: TextStyle(color: Colors.black45),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.black12, thickness: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _socialButton(
                      text: 'login with Apple',
                      icon: Icons.apple,
                      onTap: () => _showError('Apple login (кейін қосамыз)'),
                    ),
                    const SizedBox(height: 10),
                    _socialButton(
                      text: 'Login with Google',
                      icon: Icons.g_mobiledata,
                      onTap: () => _showError('Google login (кейін қосамыз)'),
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

  // ============== UI helpers ==============

  Widget _tabButton({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: active ? purple : Colors.black38,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2.5,
              width: active ? 110 : 0,
              decoration: BoxDecoration(
                color: purple,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.w600,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : Colors.black26,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : purple,
                width: 1.6,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.w600,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : Colors.black26,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : purple,
                width: 1.6,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.black38,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _socialButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.black87),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}