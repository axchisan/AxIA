enum MessageSender {
  user,
  axia,
}

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isVoice;
  final String? audioUrl;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.isVoice = false,
    this.audioUrl,
  });
}
