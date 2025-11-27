# 🎤 Guía de Implementación de Audio en AxIA

Esta guía explica cómo funciona el sistema de audio en la aplicación AxIA.

## 📦 Dependencias Instaladas

\`\`\`yaml
dependencies:
  # Audio Recording - Cross-platform
  record: ^5.1.2
  
  # Audio Playback
  just_audio: ^0.9.40
  
  # File System Access
  path_provider: ^2.1.5
  
  # Permissions
  permission_handler: ^12.0.1
  
  # Markdown Rendering
  flutter_markdown: ^0.7.4+1
\`\`\`

## 🎯 Características Implementadas

### 1. Grabación de Audio
- **Formato**: AAC/M4A (compatible con iOS y Android)
- **Calidad**: 128kbps, 44.1kHz
- **Ubicación**: Directorio temporal del dispositivo
- **Conversión**: Automática a Base64 para envío

### 2. Reproducción de Audio
- Soporte para Base64
- Soporte para URLs
- Auto-limpieza de archivos temporales

### 3. Interfaz de Usuario
- Botón dinámico: micrófono cuando campo vacío, enviar cuando hay texto
- Mantener presionado para grabar
- Soltar para enviar
- Deslizar para cancelar
- Animación visual durante grabación

## 🔧 Uso del AudioService

### Inicialización
\`\`\`dart
final audioService = AudioService();
\`\`\`

### Grabar Audio
\`\`\`dart
// Solicitar permisos
final hasPermission = await audioService.requestPermission();

if (hasPermission) {
  // Iniciar grabación
  await audioService.startRecording();
  
  // Esperar a que el usuario termine...
  
  // Detener y obtener base64
  final audioBase64 = await audioService.stopRecordingAndGetBase64();
  
  if (audioBase64 != null) {
    // Enviar al servidor
    await chatProvider.sendAudioMessage(audioBase64);
  }
}
\`\`\`

### Reproducir Audio
\`\`\`dart
// Desde Base64
await audioService.playAudioFromBase64(audioBase64String);

// Desde URL
await audioService.playAudioFromUrl('https://example.com/audio.mp3');

// Detener reproducción
await audioService.stopPlayback();
\`\`\`

## 📱 Permisos Configurados

### Android (`AndroidManifest.xml`)
\`\`\`xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
\`\`\`

### iOS (`Info.plist`)
\`\`\`xml
<key>NSMicrophoneUsageDescription</key>
<string>AxIA necesita acceso al micrófono para grabar mensajes de voz...</string>
\`\`\`

## 🌐 Flujo Completo

### Envío de Audio desde App

1. **Usuario mantiene presionado el botón de micrófono**
   - Se solicita permiso (solo la primera vez)
   - Se inicia la grabación
   - El botón cambia a rojo con animación

2. **Usuario suelta el botón**
   - Se detiene la grabación
   - Se convierte el audio a Base64
   - Se envía al backend vía WebSocket

3. **Formato de Mensaje**
\`\`\`json
{
  "event": "messages.upsert",
  "channel": "app",
  "data": {
    "message": {
      "base64": "[AUDIO_BASE64_HERE]"
    },
    "messageType": "audioMessage"
  }
}
\`\`\`

### Recepción de Audio desde AxIA

1. **Backend/n8n procesa el audio**
   - Transcribe con Whisper (opcional)
   - Genera respuesta con IA
   - Convierte respuesta a voz con ElevenLabs
   - Convierte a Base64

2. **Respuesta al WebSocket**
\`\`\`json
{
  "output": "Texto de la respuesta",
  "type": "audio",
  "debe_ser_audio": true,
  "audio_base64": "[AUDIO_BASE64_HERE]",
  "session_id": "123456"
}
\`\`\`

3. **App reproduce automáticamente**
   - ChatProvider detecta `debe_ser_audio: true`
   - Llama a `audioService.playAudioFromBase64()`
   - Usuario escucha la respuesta

## 🎨 Renderizado de Markdown

La app ahora renderiza Markdown en los mensajes de AxIA:

\`\`\`markdown
### 📋 Título Principal

**Texto en negrita**
_Texto en cursiva_
`código`

✅ Item de lista
📅 Otro item
\`\`\`

## ⚡ Optimizaciones

1. **Archivos Temporales**: Se eliminan automáticamente después de uso
2. **Permisos**: Se solicitan solo cuando son necesarios
3. **Feedback Háptico**: Vibraciones sutiles durante grabación
4. **Auto-scroll**: El chat se desplaza automáticamente a los nuevos mensajes

## 🧪 Testing

### Probar Grabación de Audio
1. Abrir el chat
2. Mantener presionado el botón de micrófono
3. Hablar durante 2-3 segundos
4. Soltar el botón
5. Verificar que aparece "🎤 Mensaje de voz" en el chat

### Probar Respuesta de Audio
1. Enviar mensaje de texto
2. Verificar que n8n responde con `debe_ser_audio: true`
3. Confirmar que el audio se reproduce automáticamente

## 🐛 Solución de Problemas

### No se puede grabar
- Verificar permisos en configuración del dispositivo
- Comprobar que el micrófono funciona en otras apps
- Ver logs: `[AudioService]` en la consola

### Audio no se reproduce
- Verificar formato Base64 válido
- Comprobar que el audio es AAC/M4A
- Ver logs de reproducción

### Mensajes no llegan
- Verificar conexión WebSocket
- Comprobar formato JSON del mensaje
- Revisar logs del backend

## 📝 Próximas Mejoras

- [ ] Visualización de forma de onda durante grabación
- [ ] Límite de tiempo de grabación
- [ ] Cancelar grabación deslizando
- [ ] Compresión adicional de audio
- [ ] Cache de mensajes de audio
- [ ] Transcripción local opcional
