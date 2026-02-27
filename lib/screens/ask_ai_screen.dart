import 'package:flutter/material.dart';

class AskAiScreen extends StatefulWidget {
  const AskAiScreen({super.key});

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color deepPurple = Color(0xFF6D2DFF);
  static const Color lightPurple = Color(0xFF8E5BFF);

  final TextEditingController _msgC = TextEditingController();
  final ScrollController _scrollC = ScrollController();

  final List<_ChatMsg> _messages = [
    const _ChatMsg(
      text:
      'Lorem Ipsum Dolor Sit Amet, Consectetur Adipiscing Elit, Sed Do Eiusmod Tempor Incididunt Ut Labore Et Dolore.',
      isMe: false,
      time: '10 AM',
      dark: true,
    ),
    const _ChatMsg(
      text:
      'Sed Do Eiusmod Tempor Incididunt Ut Labore Et Magna Aliqua. Ut Enim Ad Minim Veniam, Quis Nostrud Exercitation Ullamco Laboris Nisi Ut Aliqui.',
      isMe: false,
      time: '10 AM',
      dark: false,
    ),
    const _ChatMsg(
      text: 'Lorem Ipsum Dolor Sit',
      isMe: true,
      time: '10 AM',
      dark: true,
    ),
    const _ChatMsg(
      text:
      'Sed Do Eiusmod Tempor Incididunt Ut Labore Et Magna Aliqua. Ut Enim Ad Minim Veniam,.',
      isMe: false,
      time: '10 AM',
      dark: false,
    ),
    const _ChatMsg(
      text: 'Lorem Ipsum Dolor Sit Amet, Consectetur Adipiscing',
      isMe: false,
      time: '10 AM',
      dark: true,
    ),
    const _ChatMsg(
      text: 'Sed Do Eiusmod Tempor Incididunt Ut Labore Et',
      isMe: false,
      time: '10 AM',
      dark: false,
    ),
    const _ChatMsg(
      text: 'Ok',
      isMe: true,
      time: '10 AM',
      dark: true,
    ),
  ];

  @override
  void dispose() {
    _msgC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgC.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMsg(
          text: text,
          isMe: true,
          time: _nowTime(),
          dark: true,
        ),
      );
      _msgC.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(
          _scrollC.position.maxScrollExtent + 260,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _nowTime() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1FF),
      body: SafeArea(
        child: Column(
          children: [
            // TOP HEADER (purple + white rounded sheet)
            Container(
              width: double.infinity,
              height: 130,
              decoration: const BoxDecoration(color: purple),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(34),
                      topRight: Radius.circular(34),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Ask Ai',
                      style: TextStyle(
                        color: deepPurple,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // CHAT LIST
            Expanded(
              child: ListView.builder(
                controller: _scrollC,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _ChatBubble(
                  msg: _messages[i],
                  purpleDark: deepPurple,
                  purpleLight: lightPurple,
                ),
              ),
            ),

            // INPUT BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 18,
                      offset: Offset(0, 8),
                      color: Color(0x14000000),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.black54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _msgC,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Type message here...',
                          hintStyle: TextStyle(
                            color: Colors.black38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: deepPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Bubble widget ======

class _ChatBubble extends StatelessWidget {
  final _ChatMsg msg;
  final Color purpleDark;
  final Color purpleLight;

  const _ChatBubble({
    required this.msg,
    required this.purpleDark,
    required this.purpleLight,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = msg.dark ? purpleDark : purpleLight;
    final align = msg.isMe ? Alignment.centerRight : Alignment.centerLeft;

    final radius = msg.isMe
        ? const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(6),
    )
        : const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: Radius.circular(6),
      bottomRight: Radius.circular(20),
    );

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment:
          msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: radius,
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: const TextStyle(
                color: Colors.black38,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isMe;
  final String time;

  /// dark=true => deepPurple, dark=false => lightPurple
  final bool dark;

  const _ChatMsg({
    required this.text,
    required this.isMe,
    required this.time,
    required this.dark,
  });
}