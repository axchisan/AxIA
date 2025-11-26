# AxIA - Arquitectura de Sistema Completo

## 1. Flujo de Autenticación

\`\`\`
[Flutter App Login] 
    ↓
    POST /token (FastAPI)
    ↓
    JWT Token generado
    ↓
    Almacenado en flutter_secure_storage (Keychain/Keystore)
    ↓
    Redirige a MainNavigation
\`\`\`

## 2. Comunicación Real-time (WebSocket)

\`\`\`
[Flutter ChatScreen]
    ↓
    WebSocket Connect (wss://apiaxia.axchisan.com/ws/{user}?token={JWT})
    ↓
    [FastAPI WebSocket Endpoint]
    ↓
    Forward to n8n Webhook
    ↓
    n8n Workflow (AxIA Agent)
    ↓
    Response back through WebSocket
    ↓
    [Flutter receives and displays]
\`\`\`

## 3. Flujo de Mensajes

### Mensaje de Texto:
1. Usuario escribe en TextField
2. Click en botón enviar
3. ChatProvider.sendMessage() → WebSocket.sink.add()
4. FastAPI recibe → n8n webhook
5. AxIA procesa → respuesta
6. FastAPI envía por WebSocket
7. ChatProvider escucha y actualiza ListView

### Mensaje de Voz:
1. Usuario presiona botón micrófono
2. AudioService.startRecording()
3. Usuario suelta botón
4. AudioService.stopRecording() → convertir a base64
5. ChatProvider.sendAudioMessage() → WebSocket
6. Mismo flujo que texto pero con type: 'audio'

## 4. Endpoints FastAPI

\`\`\`
POST /token
  Input: username, password
  Output: access_token, token_type, expires_in
  
WebSocket /ws/{username}?token={token}
  Bidirectional communication
  Input: {type, text, audio_base64, session_id}
  Output: {session_id, output, type, timestamp}

POST /send-message
  Input: {text, audio_base64, type}
  Output: {session_id, output, type, timestamp}

GET /calendar/events
  Auth: Bearer token
  Output: List[CalendarEvent]

GET /tasks
  Auth: Bearer token
  Output: List[Task]

POST /tasks
  Auth: Bearer token
  Input: {title, description, due_date}
  Output: Task

GET /messages/{session_id}
  Auth: Bearer token
  Output: List[Message]

GET /health
  Output: {status: ok, timestamp}
\`\`\`

## 5. Integración n8n

El workflow n8n recibe requests en:
\`\`\`
http://n8n:5678/webhook/axia
\`\`\`

Payload:
\`\`\`json
{
  "session_id": "uuid",
  "user": "duvan",
  "timestamp": "2024-11-26T...",
  "type": "text|audio",
  "text": "mensaje",
  "audio_base64": "base64_data"
}
\`\`\`

Respuesta esperada:
\`\`\`json
{
  "output": "respuesta de AxIA",
  "type": "text|audio",
  "audio_base64": null
}
\`\`\`

## 6. Flujo de Autenticación Completo

1. **App inicia** → SplashScreen
2. **SplashScreen** → AuthProvider.checkAuthentication()
3. **Si tiene token válido** → MainNavigation
4. **Si no** → LoginScreen
5. **Usuario ingresa credenciales** → POST /token
6. **Token guardado** → flutter_secure_storage
7. **Redirige a Dashboard**
8. **En ChatScreen** → initializeWebSocket() con token
9. **WebSocket conectado** → Listo para chat

## 7. Manejo de Errores

### WebSocket Desconexión:
- Escucha onError → muestra banner rojo
- Usuario presiona "Reconectar"
- ChatProvider.reconnect() → cierra y reabre conexión

### Token Expirado:
- FastAPI retorna 401
- AuthProvider limpia token
- User redirigido a LoginScreen

### Request fallido:
- Muestra mensaje de error
- User puede reintentar

## 8. Estructura de Carpetas Flutter

\`\`\`
lib/
├── main.dart
├── config/
│   ├── api_config.dart
│   └── theme/
├── models/
│   ├── chat_message.dart
│   ├── presence_status.dart
│   ├── routine.dart
│   ├── note.dart
│   ├── project.dart
│   ├── client.dart
├── providers/
│   ├── auth_provider.dart
│   ├── chat_provider.dart
│   ├── calendar_provider.dart
│   ├── tasks_provider.dart
│   ├── presence_provider.dart
│   ├── routine_provider.dart
│   ├── notes_provider.dart
│   ├── projects_provider.dart
│   └── theme_provider.dart
├── services/
│   ├── auth_service.dart
│   ├── api_service.dart
│   ├── audio_service.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── splash_screen.dart
│   ├── dashboard/
│   ├── chat/
│   ├── presence/
│   ├── routines/
│   ├── notes/
│   ├── projects/
│   ├── settings/
│   └── main_navigation.dart
└── widgets/
    └── common/

backend/
├── main.py (FastAPI)
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
└── .env.example
\`\`\`

## 9. Deployment

### Backend (FastAPI):
\`\`\`bash
docker-compose up -d
\`\`\`

### Frontend (Flutter):
\`\`\`bash
flutter pub get
flutter run
\`\`\`

## 10. Variables de Entorno

### Backend (.env):
\`\`\`
SECRET_KEY=your-secret-key
N8N_WEBHOOK_URL=http://n8n:5678/webhook/axia
DATABASE_URL=postgresql://user:pass@postgres:5432/axia_db
\`\`\`

### Flutter (pubspec.yaml + ApiConfig):
\`\`\`dart
static const String baseUrl = 'https://apiaxia.axchisan.com';
static const String wsUrl = 'wss://apiaxia.axchisan.com/ws';
\`\`\`

## 11. Seguridad

- JWT tokens con expiración de 24h
- Tokens almacenados en Keychain/Keystore (Secure Storage)
- WebSocket autenticado con token en query param
- CORS habilitado pero restrictivo en producción
- Passwords hasheados en base de datos

## 12. Performance

- WebSocket para real-time (menor latencia que HTTP polling)
- Chat messages caché en local (Hive)
- Lazy loading en listas (ListView.builder)
- Conexión reutilizable (singleton WebSocketChannel)
