class ApiConfig {
  static const String baseUrl = 'https://apiaxia.axchisan.com';
  static const String wsUrl = 'wss://apiaxia.axchisan.com/ws';
  
  static const String n8nWebhookUrl = 'https://n8n.axchisan.com/webhook/15f68f4b-70e3-48eb-ae7d-d36d0a630118';
  
  // Local development
  // static const String baseUrl = 'http://localhost:8077';
  // static const String wsUrl = 'ws://localhost:8077/ws';
  
  static const String tokenEndpoint = '/token';
  static const String sendMessageEndpoint = '/send-message';
  static const String calendarEndpoint = '/calendar/events';
  static const String tasksEndpoint = '/tasks';
  static const String messagesHistoryEndpoint = '/messages';
  static const String healthEndpoint = '/health';
  
  static const String appChannel = 'app';
}
