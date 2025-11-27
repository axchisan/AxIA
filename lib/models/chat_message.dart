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
  final String? audioBase64;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.isVoice = false,
    this.audioUrl,
    this.audioBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender == MessageSender.user ? 'user' : 'axia',
      'timestamp': timestamp.toIso8601String(),
      'isVoice': isVoice,
      'audioUrl': audioUrl,
      'audioBase64': audioBase64,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      sender: json['sender'] == 'user' ? MessageSender.user : MessageSender.axia,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isVoice: json['isVoice'] as bool? ?? false,
      audioUrl: json['audioUrl'] as String?,
      audioBase64: json['audioBase64'] as String?,
    );
  }
}
