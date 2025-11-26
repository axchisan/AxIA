import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../models/chat_message.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;
  String? _currentSessionId;

  List<ChatMessage> get messages => _messages;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    _messages = [
      ChatMessage(
        id: '1',
        content: '¡Hola Duvan! Soy AxIA. ¿Cómo puedo ayudarte hoy?',
        sender: MessageSender.axia,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        id: '2',
        content: 'Hola AxIA, necesito recordar mi sesión de karate a las 6pm',
        sender: MessageSender.user,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      ChatMessage(
        id: '3',
        content: 'Listo, he anotado tu sesión de karate para las 6 PM. ¿Algo más?',
        sender: MessageSender.axia,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ];
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

      // Construct WebSocket URL with authentication
      final wsUrl = '${ApiConfig.wsUrl}/$currentUser?token=$token';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to incoming messages
      _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          _error = 'WebSocket error: $error';
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
      );

      _isConnected = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to connect: $e';
      _isConnected = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final axiaMessage = ChatMessage(
        id: data['session_id'] ?? DateTime.now().toString(),
        content: data['output'] ?? '',
        sender: MessageSender.axia,
        timestamp: DateTime.now(),
        isVoice: data['type'] == 'audio',
      );

      _messages.add(axiaMessage);
      notifyListeners();
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
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
    _currentSessionId = DateTime.now().toString();

    // Send through WebSocket
    final payload = jsonEncode({
      'type': 'text',
      'text': content,
      'session_id': _currentSessionId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    try {
      _channel!.sink.add(payload);
    } catch (e) {
      _error = 'Failed to send message: $e';
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
      content: '[Audio enviado]',
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      isVoice: true,
    );
    _messages.add(userMessage);

    final payload = jsonEncode({
      'type': 'audio',
      'audio_base64': audioBase64,
      'session_id': DateTime.now().toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    try {
      _channel!.sink.add(payload);
    } catch (e) {
      _error = 'Failed to send audio: $e';
    }

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
    super.dispose();
  }
}
