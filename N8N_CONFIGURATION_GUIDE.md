# 🤖 Guía de Configuración n8n para AxIA App

Esta guía te ayudará a configurar tu flujo de n8n para recibir y responder mensajes desde tu aplicación Flutter.

## 📋 Tabla de Contenidos

1. [Estructura del Flujo](#estructura-del-flujo)
2. [Identificación del Canal](#identificación-del-canal)
3. [Procesamiento de Mensajes](#procesamiento-de-mensajes)
4. [Envío de Respuestas](#envío-de-respuestas)
5. [Ejemplos de Nodos](#ejemplos-de-nodos)

---

## 🔄 Estructura del Flujo

Tu flujo n8n recibirá mensajes con la siguiente estructura:

### Mensaje de Texto desde App:
\`\`\`json
{
  "event": "messages.upsert",
  "instance": "AxIAPersonal",
  "channel": "app",
  "data": {
    "key": {
      "remoteJid": "app:AxchiSan@axia.app",
      "fromMe": false,
      "id": "1764210412809"
    },
    "pushName": "AxchiSan",
    "message": {
      "conversation": "Dime que eventos tengo para mi agenda"
    },
    "messageType": "conversation",
    "messageTimestamp": 1764210411,
    "source": "flutter_app"
  }
}
\`\`\`

### Mensaje de Audio desde App:
\`\`\`json
{
  "event": "messages.upsert",
  "instance": "AxIAPersonal",
  "channel": "app",
  "data": {
    "key": {
      "remoteJid": "app:AxchiSan@axia.app",
      "fromMe": false,
      "id": "1764210412809"
    },
    "pushName": "AxchiSan",
    "message": {
      "base64": "[BASE64_AUDIO_DATA]"
    },
    "messageType": "audioMessage",
    "messageTimestamp": 1764210411,
    "source": "flutter_app"
  }
}
\`\`\`

---

## 🎯 Identificación del Canal

### 1. Agregar Nodo Switch para Detectar Canal

Después de tu nodo Webhook, agrega un nodo **Switch** con las siguientes condiciones:

**Nodo: Switch - Detectar Canal**
- **Nombre**: "Detectar Canal de Origen"
- **Mode**: Rules

**Regla 1 - WhatsApp:**
\`\`\`javascript
{{ $json.channel === undefined || $json.channel === 'whatsapp' }}
\`\`\`
*Ruta: WhatsApp*

**Regla 2 - Telegram:**
\`\`\`javascript
{{ $json.channel === 'telegram' }}
\`\`\`
*Ruta: Telegram*

**Regla 3 - App:**
\`\`\`javascript
{{ $json.channel === 'app' }}
\`\`\`
*Ruta: App*

### 2. Modificar Validación de Usuario

Para WhatsApp, mantén tu lógica actual:
\`\`\`javascript
{{ $if($('Webhook').isExecuted, $('Webhook').item.json.body.data.key.remoteJid.split("@")[0].split(":")[0], '') }}
\`\`\`
Equals to: `573183038190`

Para App, agrega una nueva validación:
\`\`\`javascript
{{ $if($('Webhook').isExecuted, $('Webhook').item.json.data.key.remoteJid.split(":")[1].split("@")[0], '') }}
\`\`\`
Equals to: `AxchiSan@axia.app` (o el usuario que uses)

O más simple, detecta el prefijo "app:":
\`\`\`javascript
{{ $json.data.key.remoteJid.startsWith('app:') }}
\`\`\`

---

## 💬 Procesamiento de Mensajes

### Extraer Contenido del Mensaje

**Para Texto:**
\`\`\`javascript
// Detectar si es de la app
{{ $json.data.source === 'flutter_app' ? $json.data.message.conversation : $json.body.data.message.conversation }}
\`\`\`

**Para Audio:**
\`\`\`javascript
// Detectar si es audio
{{ $json.data.messageType === 'audioMessage' ? $json.data.message.base64 : null }}
\`\`\`

### Nodo IF - Determinar Tipo de Mensaje

\`\`\`javascript
// Condición para mensaje de texto
{{ $json.data.messageType === 'conversation' }}
\`\`\`

\`\`\`javascript
// Condición para mensaje de audio
{{ $json.data.messageType === 'audioMessage' }}
\`\`\`

---

## 📤 Envío de Respuestas

### Estructura de Respuesta a la App

Tu flujo debe retornar una respuesta con esta estructura al endpoint que llamó:

#### Respuesta de Texto:
\`\`\`json
{
  "output": "### 📋 Eventos de la Semana\n\n**Lunes:**\n✅ Reunión con cliente - _2:00 PM_\n📞 Llamada importante - _4:30 PM_\n\n**Miércoles:**\n🎯 Presentación proyecto - _10:00 AM_",
  "type": "text",
  "debe_ser_audio": false,
  "session_id": "1764210412809",
  "timestamp": "2025-11-27T02:26:51.510816"
}
\`\`\`

#### Respuesta de Audio:
\`\`\`json
{
  "output": "Texto de la respuesta para referencia",
  "type": "audio",
  "debe_ser_audio": true,
  "audio_base64": "[BASE64_AUDIO_DATA]",
  "audio_url": "https://optional-url-to-audio.com/file.mp3",
  "session_id": "1764210412809",
  "timestamp": "2025-11-27T02:26:51.510816"
}
\`\`\`

### Nodo HTTP Request - Enviar a App

**Configuración del Nodo:**
- **Method**: POST
- **URL**: `{{ $json.webhook_url }}` (obtener del mensaje entrante si lo incluyes)
- **Authentication**: None
- **Send Body**: Yes
- **Body Content Type**: JSON

**Body Parameters:**

\`\`\`javascript
{
  "output": "{{ $json.respuesta_texto }}",
  "type": "{{ $json.debe_ser_audio ? 'audio' : 'text' }}",
  "debe_ser_audio": {{ $json.debe_ser_audio }},
  "audio_base64": "{{ $json.audio_base64 || null }}",
  "audio_url": "{{ $json.audio_url || null }}",
  "session_id": "{{ $('Webhook').item.json.data.key.id }}",
  "timestamp": "{{ $now.toISO() }}"
}
\`\`\`

---

## 🔧 Ejemplos de Nodos Específicos

### 1. Nodo Switch - Routing Completo

\`\`\`
Webhook → Switch (Canal) → [3 rutas]
                          ↓
                    ┌─────┴─────┬─────────┐
                    ↓           ↓         ↓
                WhatsApp    Telegram    App
                    ↓           ↓         ↓
              [Lógica WA] [Lógica TG] [Lógica App]
                    ↓           ↓         ↓
                    └─────┬─────┴─────────┘
                          ↓
                  [Procesamiento IA]
                          ↓
                    Switch (Canal)
                          ↓
                    ┌─────┴─────┬─────────┐
                    ↓           ↓         ↓
            [Enviar a WA] [Enviar TG] [Respond]
\`\`\`

### 2. Nodo Code - Formatear Respuesta para App

\`\`\`javascript
// Obtener datos del webhook
const channelSource = $input.item.json.channel;
const messageData = $input.item.json.data;
const sessionId = messageData.key.id;

// Si es de la app, formatear respuesta con Markdown
if (channelSource === 'app') {
  return {
    json: {
      output: `### 📅 Tu Agenda\n\n**Eventos próximos:**\n✅ Evento 1\n📍 Evento 2`,
      type: 'text',
      debe_ser_audio: false,
      session_id: sessionId,
      timestamp: new Date().toISOString()
    }
  };
}

return $input.item;
\`\`\`

### 3. Nodo IF - Decidir Formato de Respuesta

\`\`\`javascript
// Condición para determinar si debe ser audio
{{ $json.preferencia_audio === true || $json.mensaje_original_era_audio === true }}
\`\`\`

Si TRUE → Generar audio con ElevenLabs y convertir a base64
Si FALSE → Enviar texto con formato Markdown

### 4. Nodo Function - Convertir Audio a Base64

\`\`\`javascript
const audioUrl = $input.item.json.audio_url;

// Fetch audio file
const response = await fetch(audioUrl);
const arrayBuffer = await response.arrayBuffer();
const buffer = Buffer.from(arrayBuffer);
const base64Audio = buffer.toString('base64');

return {
  json: {
    ...item.json,
    audio_base64: base64Audio
  }
};
\`\`\`

---

## 🎨 Formato de Respuestas para la App

La app soporta **Markdown completo**. Usa estos formatos:

### Texto Enriquecido:
\`\`\`markdown
### 📋 Título Principal

**Texto en negrita** para énfasis
_Texto en cursiva_ para detalles

`código` para referencias técnicas

✅ Lista con emojis
📅 Otro elemento
🎯 Tercer elemento

**Estado:** `3 de 5 completadas`
\`\`\`

### Emojis Estratégicos:
- ✅ Completado
- 🔄 En progreso
- ⏰ Pendiente
- 📅 Fecha/Evento
- 📧 Email
- 📞 Llamada
- 📍 Ubicación
- 🎯 Objetivo
- 💼 Trabajo
- 🏠 Personal

---

## ✅ Checklist de Configuración

- [ ] Agregar nodo Switch después del Webhook para detectar canal
- [ ] Modificar validación de usuario para incluir canal "app"
- [ ] Crear lógica de procesamiento específica para mensajes de app
- [ ] Configurar respuesta con formato JSON correcto
- [ ] Agregar soporte para audio (base64)
- [ ] Implementar formato Markdown en respuestas de texto
- [ ] Probar flujo completo con la app
- [ ] Verificar que las respuestas lleguen correctamente al WebSocket

---

## 🐛 Troubleshooting

### La app no recibe respuestas:
1. Verificar que el backend esté devolviendo la respuesta correctamente
2. Comprobar logs del servidor backend
3. Verificar que el WebSocket esté conectado
4. Revisar formato JSON de la respuesta

### El audio no se reproduce:
1. Verificar que `audio_base64` esté correctamente codificado
2. Comprobar que el formato de audio sea compatible (AAC/M4A)
3. Verificar que el campo `debe_ser_audio` esté en `true`

### Los mensajes no se procesan:
1. Verificar que el campo `channel: "app"` esté presente
2. Comprobar que el `remoteJid` tenga el prefijo `app:`
3. Revisar logs de n8n para errores

---

## 📞 Soporte

Para más información sobre la integración, revisar:
- Documentación del backend: `DEPLOYMENT_INSTRUCTIONS.md`
- Código del provider: `lib/providers/chat_provider.dart`
- Servicio de audio: `lib/services/audio_service.dart`
