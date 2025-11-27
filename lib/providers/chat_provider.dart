import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/chat_message.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;
  String? _currentSessionId;
  String? _currentUsername;
  SharedPreferences? _prefs;
  final AudioService _audioService = AudioService();

  List<ChatMessage> get messages => _messages;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AudioService get audioService => _audioService;

  ChatProvider() {
    _initStorage();
  }

  Future<void> _initStorage() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadMessagesFromStorage();
  }

  Future<void> _loadMessagesFromStorage() async {
    if (_prefs == null) return;
    
    final messagesJson = _prefs!.getString('chat_messages');
    if (messagesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(messagesJson);
        _messages = decoded.map((json) => ChatMessage.fromJson(json)).toList();
        notifyListeners();
      } catch (e) {
        print('[ChatProvider] Error loading messages: $e');
        _loadMockData();
      }
    } else {
      _loadMockData();
    }
  }

  Future<void> _saveMessagesToStorage() async {
    if (_prefs == null) return;
    
    try {
      final messagesJson = jsonEncode(
        _messages.map((msg) => msg.toJson()).toList(),
      );
      await _prefs!.setString('chat_messages', messagesJson);
    } catch (e) {
      print('[ChatProvider] Error saving messages: $e');
    }
  }

  void _loadMockData() {
    _messages = [
      ChatMessage(
        id: '1',
        content: '### 👋 ¡Hola! Soy **AxIA**\n\nTu asistente personal inteligente. ¿En qué puedo ayudarte hoy?\n\n✅ Gestiona tu agenda\n📧 Revisa correos\n📝 Organiza tareas\n🎯 Y mucho más...',
        sender: MessageSender.axia,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
    _saveMessagesToStorage();
    notifyListeners();
  }

  Future<void> initializeWebSocket() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final authService = AuthService();
      final token = await authService.getToken();
      final currentUser = await authService.getCurrentUser();

      if (token == null || currentUser == null) {
        _error = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentUsername = currentUser;

      final wsUrl = '${ApiConfig.wsUrl}/$currentUser?token=$token';
      
      print('[ChatProvider] Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to incoming messages
      _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          _error = 'WebSocket error: $error';
          _isConnected = false;
          print('[ChatProvider] WebSocket error: $error');
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          print('[ChatProvider] WebSocket connection closed');
          notifyListeners();
        },
      );

      _isConnected = true;
      _isLoading = false;
      print('[ChatProvider] WebSocket connected successfully');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to connect: $e';
      _isConnected = false;
      _isLoading = false;
      print('[ChatProvider] Connection error: $e');
      notifyListeners();
    }
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      String content = data['output'] ?? data['text'] ?? '';
      bool isVoiceResponse = data['type'] == 'audio' || data['debe_ser_audio'] == true;
      String? audioUrl = data['audio_url'];
      String? audioBase64 = data['audio_base64'];
      
      final axiaMessage = ChatMessage(
        id: data['session_id'] ?? DateTime.now().toString(),
        content: content,
        sender: MessageSender.axia,
        timestamp: DateTime.now(),
        isVoice: isVoiceResponse,
        audioUrl: audioUrl,
        audioBase64: audioBase64,
      );

      _messages.add(axiaMessage);
      _saveMessagesToStorage();
      
      if (isVoiceResponse && (audioBase64 != null || audioUrl != null)) {
        if (audioBase64 != null) {
          _audioService.playAudioFromBase64(audioBase64);
        } else if (audioUrl != null) {
          _audioService.playAudioFromUrl(audioUrl);
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('[ChatProvider] Error parsing message: $e');
    }
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    _saveMessagesToStorage();
    notifyListeners();
  }

  void sendMessage(String content) {
    if (!_isConnected || _channel == null) {
      _error = 'WebSocket not connected';
      notifyListeners();
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().toString(),
      content: content,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _saveMessagesToStorage();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final payload = jsonEncode({
      'event': 'messages.upsert',
      'instance': 'AxIAPersonal',
      'channel': ApiConfig.appChannel,
      'data': {
        'key': {
          'remoteJid': 'app:${_currentUsername}@axia.app',
          'fromMe': false,
          'id': _currentSessionId,
        },
        'pushName': _currentUsername,
        'message': {
          'conversation': content,
        },
        'messageType': 'conversation',
        'messageTimestamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        'source': 'flutter_app',
      },
      'destination': ApiConfig.n8nWebhookUrl,
      'date_time': DateTime.now().toIso8601String(),
      'sender': '${_currentUsername}@axia.app',
    });

    try {
      _channel!.sink.add(payload);
      print('[ChatProvider] Message sent: $content');
    } catch (e) {
      _error = 'Failed to send message: $e';
      print('[ChatProvider] Send error: $e');
    }

    notifyListeners();
  }

  Future<void> sendAudioMessage(String audioBase64) async {
    if (!_isConnected || _channel == null) {
      _error = 'WebSocket not connected';
      notifyListeners();
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().toString(),
      content: '🎤 Mensaje de voz',
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      isVoice: true,
    );
    _messages.add(userMessage);
    _saveMessagesToStorage();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final payload = jsonEncode({
      'event': 'messages.upsert',
      'instance': 'AxIAPersonal',
      'channel': ApiConfig.appChannel,
      'data': {
        'key': {
          'remoteJid': 'app:${_currentUsername}@axia.app',
          'fromMe': false,
          'id': _currentSessionId,
        },
        'pushName': _currentUsername,
        'message': {
          'base64': audioBase64,
        },
        'messageType': 'audioMessage',
        'messageTimestamp': (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        'source': 'flutter_app',
      },
      'destination': ApiConfig.n8nWebhookUrl,
      'date_time': DateTime.now().toIso8601String(),
      'sender': '${_currentUsername}@axia.app',
    });

    try {
      _channel!.sink.add(payload);
      print('[ChatProvider] Audio message sent (${audioBase64.length} chars)');
    } catch (e) {
      _error = 'Failed to send audio: $e';
      print('[ChatProvider] Audio send error: $e');
    }

    notifyListeners();
  }

  Future<void> clearMessages() async {
    _messages.clear();
    await _prefs?.remove('chat_messages');
    _loadMockData();
    notifyListeners();
  }

  Future<void> reconnect() async {
    close();
    await Future.delayed(const Duration(seconds: 1));
    await initializeWebSocket();
  }

  void close() {
    _channel?.sink.close();
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    close();
    _audioService.dispose();
    super.dispose();
  }
}
