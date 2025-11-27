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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender == MessageSender.user ? 'user' : 'axia',
      'timestamp': timestamp.toIso8601String(),
      'isVoice': isVoice,
      'audioUrl': audioUrl,
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
    );
  }
}
