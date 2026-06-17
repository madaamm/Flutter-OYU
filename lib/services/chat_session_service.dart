class AiChatMessage {
  final bool isAi;
  final String text;

  const AiChatMessage({
    required this.isAi,
    required this.text,
  });

  const AiChatMessage.user(this.text) : isAi = false;

  const AiChatMessage.ai(this.text) : isAi = true;
}

class ChatSessionService {
  static final List<AiChatMessage> _messages = [];

  static List<AiChatMessage> snapshot() =>
      List<AiChatMessage>.unmodifiable(_messages);

  static void ensureGreeting(String greeting) {
    if (_messages.isEmpty) {
      _messages.add(AiChatMessage.ai(greeting));
    }
  }

  static void addUserMessage(String text) {
    _messages.add(AiChatMessage.user(text));
  }

  static void addAiPlaceholder() {
    _messages.add(const AiChatMessage.ai('...'));
  }

  static void replaceLastPlaceholder(String text) {
    final idx = _messages.lastIndexWhere((m) => m.isAi && m.text == '...');
    if (idx != -1) {
      _messages[idx] = AiChatMessage.ai(text);
      return;
    }
    _messages.add(AiChatMessage.ai(text));
  }

  static void removeLastPlaceholder() {
    if (_messages.isNotEmpty &&
        _messages.last.isAi &&
        _messages.last.text == '...') {
      _messages.removeLast();
    }
  }

  static void clear() {
    _messages.clear();
  }
}
