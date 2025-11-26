import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => _messages;

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

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void sendMessage(String content) {
    final userMessage = ChatMessage(
      id: DateTime.now().toString(),
      content: content,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    
    // Simular respuesta de AxIA después de un pequeño delay
    Future.delayed(const Duration(milliseconds: 800), () {
      final axiaMessage = ChatMessage(
        id: DateTime.now().toString(),
        content: _generateAxiaResponse(content),
        sender: MessageSender.axia,
        timestamp: DateTime.now(),
      );
      _messages.add(axiaMessage);
      notifyListeners();
    });

    notifyListeners();
  }

  String _generateAxiaResponse(String userMessage) {
    // Respuestas simuladas inteligentes
    final responses = [
      'Entendido, lo anotaré para más tarde.',
      'Perfecto, ya está registrado en tu agenda.',
      'Claro, déjamelo a mí. Te lo recordaré.',
      'Listo boss, todo controlado.',
      '✓ Anotado. ¿Algo más que necesites?',
    ];
    return responses[userMessage.hashCode % responses.length];
  }
}
