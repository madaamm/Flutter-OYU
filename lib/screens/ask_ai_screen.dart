import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/l10n/app_text.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/services/chat_service.dart';

class AskAiScreen extends StatefulWidget {
  const AskAiScreen({super.key});

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  static const purple = Color(0xFF3D0067);

  final _c = TextEditingController();
  final _scroll = ScrollController();

  bool sending = false;
  final List<_Msg> messages = [];

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<int> _getUserId() async {
    final me = await AuthService().me();
    final id = me['id'];
    if (id is int) return id;
    return int.tryParse(id.toString()) ?? 0;
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _c.text.trim();
    if (text.isEmpty || sending) return;

    FocusScope.of(context).unfocus();

    setState(() {
      sending = true;
      messages.add(_Msg.user(text));
      _c.clear();
      messages.add(_Msg.ai('...'));
    });
    _scrollDown();

    try {
      final userId = await _getUserId();
      if (userId == 0) throw Exception(context.tr('chat_user_id_error'));

      final reply = await ChatService.sendMessage(userId: userId, message: text);

      setState(() {
        final idx = messages.lastIndexWhere((m) => m.isAi && m.text == '...');
        if (idx != -1) {
          messages[idx] = _Msg.ai(reply);
        } else {
          messages.add(_Msg.ai(reply));
        }
      });
      _scrollDown();
    } catch (e) {
      setState(() {
        if (messages.isNotEmpty && messages.last.isAi && messages.last.text == '...') {
          messages.removeLast();
        }
      });
      _error(context.tr('chat_error', args: {'error': '$e'}));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      appBar: AppBar(
        backgroundColor: purple,
        title: Text(context.tr('ask_ai'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              itemCount: messages.length,
              itemBuilder: (_, i) => _Bubble(msg: messages[i]),
            ),
          ),
          _Composer(
            controller: _c,
            sending: sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final bool isAi;
  final String text;

  _Msg({required this.isAi, required this.text});

  factory _Msg.user(String t) => _Msg(isAi: false, text: t);
  factory _Msg.ai(String t) => _Msg(isAi: true, text: t);
}

class _Bubble extends StatelessWidget {
  static const purple = Color(0xFF3D0067);
  final _Msg msg;

  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isAi = msg.isAi;

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(
          color: isAi ? purple : purple.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  static const purple = Color(0xFF3D0067);

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.black),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: context.tr('type_message'),
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: ElevatedButton(
                onPressed: sending ? null : onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 0,
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Transform.translate(
                        offset: const Offset(0, -2),
                        child: const Icon(Icons.send),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
