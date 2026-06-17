import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kazakh_learning_app/l10n/app_text.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/services/writing_service.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  static const Color gold = Color(0xFFFFC400);
  static const Color darkGold = Color(0xFFFFB300);
  static const Color ink = Color(0xFF2A2112);
  static const Color page = Color(0xFFFFF9E8);

  static const List<String> _topics = [
    'Menin otbasym',
    'Menin dosym',
    'Menin kunim',
    'Menin armanym',
    'Menin kalam',
    'Menin universitetim',
    'Kazakhstan turaly',
    'Sporttyn paidasy',
    'Tabigat jane ekologiya',
    'Sayahat turaly',
  ];

  final TextEditingController _customTopicController = TextEditingController();
  String? _selectedTopic;

  @override
  void dispose() {
    _customTopicController.dispose();
    super.dispose();
  }

  void _openEditor() {
    final customTopic = _customTopicController.text.trim();
    final topic = customTopic.isNotEmpty ? customTopic : (_selectedTopic ?? '').trim();

    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('choose_topic_first'))),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WritingComposeScreen(topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customTopicFilled = _customTopicController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const Expanded(
                  child: Text(
                    'Writing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [gold, darkGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note_rounded, size: 52, color: ink),
                  SizedBox(height: 18),
                  Text(
                    context.tr('writing_choose_topic'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    context.tr('writing_choose_topic_desc'),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              context.tr('popular_topics'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _topics
                  .map(
                    (topic) => _TopicChip(
                      title: topic,
                      selected: !customTopicFilled && _selectedTopic == topic,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _selectedTopic = topic;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1D46A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('your_own_topic'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customTopicController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: context.tr('your_own_topic_hint'),
                      filled: true,
                      fillColor: const Color(0xFFFFF7D8),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _openEditor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  context.tr('continue_to_writing'),
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
    );
  }
}

class WritingComposeScreen extends StatefulWidget {
  final String topic;

  const WritingComposeScreen({
    super.key,
    required this.topic,
  });

  @override
  State<WritingComposeScreen> createState() => _WritingComposeScreenState();
}

class _WritingComposeScreenState extends State<WritingComposeScreen> {
  static const Color gold = Color(0xFFFFC400);
  static const Color ink = Color(0xFF2A2112);
  static const Color page = Color(0xFFFFF9E8);

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _sending = false;
  String? _aiResponse;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<int> _getUserId() async {
    final me = await AuthService().me();
    final id = me['id'];
    if (id is int) return id;
    return int.tryParse(id.toString()) ?? 0;
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _sending = true;
      _aiResponse = null;
    });

    try {
      final userId = await _getUserId();
      if (userId == 0) {
        throw Exception(context.tr('writing_user_error'));
      }

      final reply = await WritingService.evaluateWriting(
        userId: userId,
        topic: widget.topic,
        text: text,
        timeout: const Duration(seconds: 90),
      );

      if (!mounted) return;
      setState(() {
        _aiResponse = reply;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 240,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('writing_timeout')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('check_error', args: {'error': '$e'}),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _textController.text.trim().length;

    return Scaffold(
      backgroundColor: page,
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                Expanded(
                  child: Text(
                    context.tr('writing_practice'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF0D46B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('topic'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7A6A35),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.topic,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('write_in_kazakh'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('write_in_kazakh_desc'),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF6A6557),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _textController,
                    minLines: 10,
                    maxLines: 16,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: context.tr('write_here'),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: const Color(0xFFFFFBEE),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        context.tr('chars', args: {'count': '$charCount'}),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF817A68),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        charCount < 20
                            ? context.tr('write_1_2_sentences')
                            : context.tr('ready_to_send'),
                        style: TextStyle(
                          fontSize: 13,
                          color: charCount < 20 ? const Color(0xFF9B6B00) : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _sending || charCount == 0 ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ink,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFBEB7A2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              context.tr('send_for_checking'),
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
            if (_aiResponse != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: gold),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy_outlined, color: ink),
                        SizedBox(width: 10),
                        Text(
                          context.tr('writing_feedback'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    MarkdownBody(
                      data: _aiResponse!,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: ink,
                        ),
                        strong: const TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                        listBullet: const TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: ink,
                        ),
                        blockSpacing: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _TopicChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _WritingScreenState.ink : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _WritingScreenState.ink : const Color(0xFFE8D58E),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _WritingScreenState.ink,
          ),
        ),
      ),
    );
  }
}
