# Configuración de n8n para enviar mensajes a la App AxIA

## Endpoint para que n8n envíe respuestas

Tu backend ahora tiene un endpoint HTTP para recibir respuestas de n8n y enviarlas al WebSocket de la app.

### URL del Endpoint
\`\`\`
POST https://apiaxia.axchisan.com/app-message
\`\`\`

### Headers Requeridos
\`\`\`json
{
  "Content-Type": "application/json"
}
\`\`\`

**IMPORTANTE:** Este endpoint NO requiere autenticación Bearer token porque es llamado por n8n, no por el usuario.

## Configuración en n8n

### 1. Detectar que el mensaje viene de la app

En tu flujo n8n, después del nodo Webhook, agrega un nodo **Switch** para detectar el canal:

**Nodo Switch - Configuración:**
- **Mode:** Rules
- **Output Key:** channel
- **Rules:**
  - **Rule 1:** 
    - Condition: `{{ $json.channel }}` equals `app`
    - Output: 0 (Ruta para mensajes de la app)
  - **Rule 2:** 
    - Condition: `{{ $json.channel }}` equals `whatsapp`
    - Output: 1 (Ruta para WhatsApp)
  - **Rule 3:**
    - Condition: `{{ $json.channel }}` equals `telegram`
    - Output: 2 (Ruta para Telegram)

### 2. Procesar respuesta de AxIA

Después de que AxIA genere la respuesta (OpenAI, Anthropic, etc.), necesitas extraer:
- El username del usuario de la app
- El session_id original
- La respuesta generada
- Si debe ser audio o texto

**Nodo Set para preparar datos:**

\`\`\`javascript
// Extraer username desde el remoteJid
const remoteJid = $('Webhook').item.json.body.data.key.remoteJid;
const username = remoteJid.split(':')[1].split('@')[0];

// Extraer session_id
const sessionId = $('Webhook').item.json.body.data.key.id;

// Respuesta de AxIA (asumiendo que viene del nodo anterior)
const axiaResponse = $json.output || $json.text || '';

// Determinar si debe ser audio
const debeSerAudio = $json.debe_ser_audio || false;

return {
  username: username,
  session_id: sessionId,
  output: axiaResponse,
  type: debeSerAudio ? 'audio' : 'text',
  debe_ser_audio: debeSerAudio,
  audio_url: null,
  audio_base64: null
};
\`\`\`

### 3. Si la respuesta es de voz (audio)

Si `debe_ser_audio` es `true`, debes:

1. **Convertir texto a audio con ElevenLabs** (o tu servicio de TTS)
2. **Convertir audio a Base64**

**Nodo HTTP Request - ElevenLabs:**
\`\`\`
POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
\`\`\`

Headers:
\`\`\`json
{
  "xi-api-key": "tu_api_key_elevenlabs",
  "Content-Type": "application/json"
}

Body:
{
  "text": "{{ $json.output }}",
  "model_id": "eleven_multilingual_v2",
  "voice_settings": {
    "stability": 0.5,
    "similarity_boost": 0.75
  }
}
\`\`\`

**Response Format:** Set to "File"

**Nodo Convert to Base64:**
Usa un nodo Code para convertir el audio a Base64:

\`\`\`javascript
const audioBuffer = $input.first().binary.data;
const audioBase64 = audioBuffer.toString('base64');

return {
  ...​$json,
  audio_base64: audioBase64,
  audio_url: null  // o puedes subir a un CDN y poner la URL aquí
};
\`\`\`

### 4. Enviar respuesta a la App

**Nodo HTTP Request - Final:**

\`\`\`
Method: POST
URL: https://apiaxia.axchisan.com/app-message
\`\`\`

**Headers:**
\`\`\`json
{
  "Content-Type": "application/json"
}
\`\`\`

**Body (JSON):**
\`\`\`json
{
  "username": "{{ $json.username }}",
  "session_id": "{{ $json.session_id }}",
  "output": "{{ $json.output }}",
  "type": "{{ $json.type }}",
  "debe_ser_audio": {{ $json.debe_ser_audio }},
  "audio_url": {{ $json.audio_url || null }},
  "audio_base64": "{{ $json.audio_base64 }}"
}
\`\`\`

## Estructura Completa del Flujo n8n

\`\`\`
Webhook (recibe de app/whatsapp/telegram)
  ↓
Switch (detecta canal)
  ├─ Output 0: app
  │   ↓
  │   Validar Usuario (tu lógica actual)
  │   ↓
  │   Procesar con AxIA (OpenAI/Anthropic)
  │   ↓
  │   Switch: ¿Debe ser audio?
  │   ├─ Sí: ElevenLabs → Convert Base64
  │   └─ No: Continuar
  │   ↓
  │   Set (preparar JSON para app)
  │   ↓
  │   HTTP Request → /app-message
  │
  ├─ Output 1: whatsapp
  │   ↓
  │   [Tu lógica actual de WhatsApp]
  │   ↓
  │   HTTP Request → Evolution API
  │
  └─ Output 2: telegram
      ↓
      [Tu lógica actual de Telegram]
      ↓
      Telegram Send Message
\`\`\`

## Ejemplo de Payload Completo

**Texto:**
\`\`\`json
{
  "username": "AxchiSan",
  "session_id": "e15c2816-135e-45d7-9b58-a6c307f1b5b3",
  "output": "Hola, estos son tus eventos de la semana:\n\n- Lunes: Reunión con el equipo\n- Miércoles: Presentación del proyecto",
  "type": "text",
  "debe_ser_audio": false,
  "audio_url": null,
  "audio_base64": null
}
\`\`\`

**Audio:**
\`\`\`json
{
  "username": "AxchiSan",
  "session_id": "e15c2816-135e-45d7-9b58-a6c307f1b5b3",
  "output": "Tienes 3 eventos esta semana",
  "type": "audio",
  "debe_ser_audio": true,
  "audio_url": null,
  "audio_base64": "UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA="
}
\`\`\`

## Testing

Puedes probar el endpoint directamente con curl:

\`\`\`bash
curl -X POST https://apiaxia.axchisan.com/app-message \
  -H "Content-Type: application/json" \
  -d '{
    "username": "AxchiSan",
    "session_id": "test-123",
    "output": "Hola desde n8n",
    "type": "text",
    "debe_ser_audio": false,
    "audio_url": null,
    "audio_base64": null
  }'
\`\`\`

Si el usuario está conectado al WebSocket, recibirá el mensaje instantáneamente en la app.

## Notas Importantes

1. El `username` debe coincidir exactamente con el usuario que inició sesión en la app
2. Si no hay conexiones WebSocket activas, el endpoint devolverá `status: "no_active_connections"`
3. El backend automáticamente envía el mensaje a todos los dispositivos conectados del usuario
4. Para audio, puedes enviar tanto `audio_base64` como `audio_url`, pero `audio_base64` tiene prioridad
