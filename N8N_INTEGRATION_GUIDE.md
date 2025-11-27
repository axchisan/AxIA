# Guía de Integración n8n con AxIA App

## Resumen de Cambios

Esta aplicación ahora envía mensajes a tu flujo n8n en el mismo formato que Evolution API (WhatsApp), pero con un identificador especial para diferenciar los mensajes de la app.

## Formato de Datos Enviados desde la App

### Mensajes de Texto

\`\`\`json
{
  "event": "messages.upsert",
  "instance": "AxIAPersonal",
  "channel": "app",
  "data": {
    "key": {
      "remoteJid": "app:AxchiSan@axia.app",
      "fromMe": false,
      "id": "1732659417635"
    },
    "pushName": "AxchiSan",
    "message": {
      "conversation": "que correos he recibido hoy"
    },
    "messageType": "conversation",
    "messageTimestamp": 1732659417,
    "source": "flutter_app"
  },
  "destination": "https://n8n.axchisan.com/webhook/15f68f4b-70e3-48eb-ae7d-d36d0a630118",
  "date_time": "2025-11-27T00:16:57.635730",
  "sender": "AxchiSan@axia.app"
}
\`\`\`

### Mensajes de Audio

\`\`\`json
{
  "event": "messages.upsert",
  "instance": "AxIAPersonal",
  "channel": "app",
  "data": {
    "key": {
      "remoteJid": "app:AxchiSan@axia.app",
      "fromMe": false,
      "id": "1732659500000"
    },
    "pushName": "AxchiSan",
    "message": {
      "base64": "BASE64_AUDIO_DATA_HERE"
    },
    "messageType": "audioMessage",
    "messageTimestamp": 1732659500,
    "source": "flutter_app"
  },
  "destination": "https://n8n.axchisan.com/webhook/15f68f4b-70e3-48eb-ae7d-d36d0a630118",
  "date_time": "2025-11-27T00:18:20.000000",
  "sender": "AxchiSan@axia.app"
}
\`\`\`

## Diferencias Clave con WhatsApp

| Campo | WhatsApp | App AxIA |
|-------|----------|----------|
| `channel` | No existe | `"app"` |
| `data.key.remoteJid` | `573183038190:24@s.whatsapp.net` | `app:AxchiSan@axia.app` |
| `data.source` | `"android"` | `"flutter_app"` |
| `sender` | `573173012598@s.whatsapp.net` | `AxchiSan@axia.app` |

## Modificaciones Necesarias en n8n

### 1. Agregar Detección de Canal

En tu nodo Webhook, después de recibir el mensaje, agrega un nodo **Switch** o **IF** para detectar el canal:

\`\`\`javascript
// Expresión para detectar canal
{{ $json.body.channel }}

// O verificar el remoteJid
{{ $json.body.data.key.remoteJid.startsWith('app:') }}
\`\`\`

### 2. Modificar la Verificación de Usuario

Tu flujo actual verifica el usuario así:

\`\`\`javascript
{{ $if($('Webhook').isExecuted, $('Webhook').item.json.body.data.key.remoteJid.split("@")[0].split(":")[0], '') }}
\`\`\`

**Problema:** Para mensajes de WhatsApp el formato es `573183038190:24@s.whatsapp.net`, pero para la app es `app:AxchiSan@axia.app`.

**Solución:** Modifica la expresión para manejar ambos casos:

\`\`\`javascript
{{
  $if($('Webhook').isExecuted, 
    (() => {
      const remoteJid = $('Webhook').item.json.body.data.key.remoteJid;
      const channel = $('Webhook').item.json.body.channel;
      
      // Si es de la app, extraer el nombre de usuario
      if (channel === 'app' || remoteJid.startsWith('app:')) {
        return remoteJid.split(':')[1].split('@')[0];
      }
      
      // Si es de WhatsApp, usar la lógica anterior
      return remoteJid.split('@')[0].split(':')[0];
    })(), 
    ''
  )
}}
\`\`\`

O más simple, si solo necesitas validar que sea tu usuario:

\`\`\`javascript
{{
  $if($('Webhook').isExecuted, 
    (() => {
      const remoteJid = $('Webhook').item.json.body.data.key.remoteJid;
      const channel = $('Webhook').item.json.body.channel;
      
      // Si es de la app
      if (channel === 'app') {
        return remoteJid.includes('AxchiSan') ? 'AxchiSan' : '';
      }
      
      // Si es de WhatsApp
      return remoteJid.split('@')[0].split(':')[0];
    })(), 
    ''
  )
}}
\`\`\`

### 3. Enviar Respuesta de Vuelta a la App

Tu flujo debe devolver una respuesta en formato JSON al webhook. La app espera este formato:

\`\`\`json
{
  "output": "Tu respuesta aquí",
  "type": "text",
  "debe_ser_audio": false,
  "audio_url": null
}
\`\`\`

Para mensajes de audio:

\`\`\`json
{
  "output": "Respuesta convertida a texto",
  "type": "audio",
  "debe_ser_audio": true,
  "audio_url": "https://tu-servidor.com/audio/respuesta.mp3"
}
\`\`\`

### 4. Estructura Recomendada del Flujo

\`\`\`
Webhook
  ↓
Switch (detectar canal)
  ↓
├─→ [WhatsApp] → Verificar usuario WhatsApp → Procesar → Responder a WhatsApp
  ↓
└─→ [App] → Verificar usuario App → Procesar → Responder a App (JSON)
\`\`\`

## Ejemplo de Nodo Switch

**Modo:** Rules
**Output Key:** channel

**Regla 1 - WhatsApp:**
- Condición: `{{ $json.body.channel }}` no existe o es diferente de "app"
- Output: 0

**Regla 2 - App:**
- Condición: `{{ $json.body.channel === 'app' }}`
- Output: 1

## Variables de Entorno

Asegúrate de tener estas variables en tu backend:

\`\`\`bash
SECRET_KEY=tu-secret-key-aqui
N8N_WEBHOOK_URL=https://n8n.axchisan.com/webhook/15f68f4b-70e3-48eb-ae7d-d36d0a630118
DATABASE_URL=postgresql://user:password@host:5432/database
\`\`\`

## Pruebas

### Probar desde la App

1. Inicia sesión en la app
2. Ve a la sección de Chat
3. Envía un mensaje de prueba
4. Verifica en n8n que el webhook se ejecutó con `channel: "app"`

### Probar desde WhatsApp

1. Envía un mensaje a tu número de WhatsApp conectado a Evolution API
2. Verifica que el flujo identifica correctamente que NO viene de la app

## Solución de Problemas

### Error: "WebSocket not upgraded"

**Solución:** Asegúrate de que tu servidor Nginx o proxy esté configurado para WebSockets:

\`\`\`nginx
location /ws/ {
    proxy_pass http://backend:8077;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
}
\`\`\`

### Error: n8n no responde

**Verificar:** 
1. El webhook URL es correcto
2. El flujo n8n está activado
3. Los logs del backend muestran la respuesta de n8n

### Mensajes no se guardan localmente

**Solución:** Los mensajes ahora se guardan automáticamente en `shared_preferences`. Si no aparecen:

\`\`\`dart
// Limpiar el almacenamiento y reiniciar
await context.read<ChatProvider>().clearMessages();
\`\`\`

## Próximos Pasos

1. Implementar integración con Google Calendar API
2. Agregar soporte para imágenes en el chat
3. Mejorar el sistema de notificaciones push
4. Implementar sincronización de tareas con Google Tasks

## Contacto

Para más ayuda, revisa los logs del backend o del flujo n8n para ver exactamente qué datos se están enviando.
