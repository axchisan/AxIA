class ApiConfig {
  static const String baseUrl = 'https://apiaxia.axchisan.com';
  static const String wsUrl = 'wss://apiaxia.axchisan.com/ws';
  
  // Local development
  // static const String baseUrl = 'http://localhost:8000';
  // static const String wsUrl = 'ws://localhost:8000/ws';
  
  static const String tokenEndpoint = '/token';
  static const String sendMessageEndpoint = '/send-message';
  static const String calendarEndpoint = '/calendar/events';
  static const String tasksEndpoint = '/tasks';
  static const String messagesHistoryEndpoint = '/messages';
  static const String healthEndpoint = '/health';
}
