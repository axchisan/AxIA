# AxIA - Personal Life & Work Control Center

Una aplicación móvil futurista y elegante que sirve como tu centro de control personal absoluto. Combina inteligencia artificial, gestión de tareas, control de presencia y comunicación en una única interfaz hermosa.

## Características Principales

### 1. Dashboard Principal
- Greeting card personalizado según la hora del día
- Vista rápida de tareas, mensajes y proyectos activos
- Control de tema oscuro/claro
- Animaciones suaves en segundo plano

### 2. Chat con AxIA
- Conversación natural con tu asistente IA personal
- Typing indicators animados
- Soporte para mensajes de voz
- Comandos especiales (/rutina, /recordar, /agenda, etc.)
- Acciones contextuales (copiar, eliminar, marcar)
- Integración con calendario y recordatorios

### 3. Control de Presencia
- 4 estados: Disponible, Enfoque, Ausente, Ocupado
- Mensajes de ausencia personalizados
- Sincronización con WhatsApp, Email y otras plataformas
- Respuestas automáticas via AxIA

### 4. Rutinas y Hábitos
- Tracking de 4 rutinas: Karate, Código, Inglés, Meditación
- Sistema de racha (streak) para motivación
- Progreso visual diario
- Integración con calendario

### 5. Notas Privadas
- Notas ultra seguras y privadas
- Fijación de notas importantes
- Sistema de tags y búsqueda
- Respaldo automático

### 6. Gestión de Proyectos (Axchisan.com)
- Vista de todos los proyectos activos
- Seguimiento de progreso
- Gestión de clientes
- Tecnologías utilizadas por proyecto

### 7. Ajustes
- Configuración de voz de AxIA
- Personalización de la IA
- Integración con FastAPI backend
- Sincronización de datos

## Tecnología

### Frontend
- **Framework**: Flutter 3.x+ (versión más reciente)
- **State Management**: Provider 6.x
- **UI/UX**: 
  - Glassmorphism
  - Animaciones premium
  - Tema oscuro primario con acentos morados/violetas
  - Tipografía Space Grotesk

### Backend (Próximo)
- **Framework**: FastAPI (Python)
- **Base de Datos**: PostgreSQL
- **Automatización**: n8n
- **IA**: Integración con LLMs

### Dependencias Principales
\`\`\`yaml
provider: ^6.2.1          # State management
speech_to_text: ^6.6.3    # Reconocimiento de voz
flutter_tts: ^5.8.1       # Text-to-speech
google_fonts: ^6.2.1      # Tipografía moderna
flutter_animate: ^4.5.0   # Animaciones
shimmer: ^3.0.0           # Skeleton loading
dio: ^5.4.2               # HTTP client
hive: ^2.2.3              # Local storage
\`\`\`

## Instalación

### Requisitos
- Flutter 3.4.0 o superior
- Dart 3.2.0 o superior
- Android SDK 21+ / iOS 12.0+

### Pasos

1. **Clonar el repositorio**
\`\`\`bash
git clone https://github.com/duvan/axia.git
cd axia
\`\`\`

2. **Instalar dependencias**
\`\`\`bash
flutter pub get
\`\`\`

3. **Ejecutar la app**
\`\`\`bash
flutter run
\`\`\`

### Variables de Entorno (Próximamente)
Crear archivo `.env` en la raíz del proyecto:
\`\`\`
BACKEND_URL=http://localhost:8000
API_KEY=tu_api_key_aqui
\`\`\`

## Estructura del Proyecto

\`\`\`
lib/
├── main.dart                  # Punto de entrada
├── config/
│   └── theme/                # Sistema de colores y tipografía
├── models/                    # Modelos de datos
├── providers/                 # State management con Provider
├── screens/
│   ├── main_navigation.dart   # Navegación principal
│   ├── dashboard/             # Dashboard screen
│   ├── chat/                  # Chat screen
│   ├── presence/              # Presence screen
│   ├── routines/              # Routines screen
│   ├── notes/                 # Notes screen
│   ├── projects/              # Projects screen
│   └── settings/              # Settings screen
├── widgets/
│   ├── common/                # Componentes reutilizables
│   ├── glass_morphism/        # Widgets glassmorphism
│   └── animations/            # Animaciones customizadas
├── services/                  # Servicios (voz, notificaciones)
└── utils/                     # Utilidades y helpers
\`\`\`

## Funcionalidades Escalables

### Fase 1 - Actual (UI + Simulada)
- Todas las pantallas con UI completa
- Datos simulados y providers
- Navegación funcional
- Tema oscuro/claro
- Animaciones premium

### Fase 2 - Backend Integration
- Conectar con FastAPI
- Autenticación real
- Base de datos PostgreSQL
- Sincronización de datos

### Fase 3 - IA Avanzada
- Integración con n8n
- Respuestas inteligentes de AxIA
- Análisis de sentimientos
- Sugerencias automáticas

### Fase 4 - Características Premium
- Reconocimiento de voz en tiempo real
- Sincronización con WhatsApp/Email
- Respuestas automáticas
- Analytics y reportes

## Próximas Mejoras

- [ ] Autenticación con Supabase
- [ ] Base de datos real con Firebase/PostgreSQL
- [ ] Reconocimiento de voz activo ("Hey AxIA")
- [ ] Sincronización con Google Calendar
- [ ] Respuestas automáticas en WhatsApp
- [ ] Análisis de productividad
- [ ] Modo focus mejorado
- [ ] Exportación de datos

## Desarrollo Local

### Hot Reload
\`\`\`bash
flutter run -v
\`\`\`

### Build Release
\`\`\`bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
\`\`\`

### Análisis de Código
\`\`\`bash
flutter analyze
\`\`\`

## Notas de Diseño

### Paleta de Colores
- **Primary**: Violeta profundo (#7C3AED)
- **Secondary**: Violeta oscuro (#6D28D9)
- **Accent**: Morado/Violeta neon (#BB86FC, #00D9FF)
- **Background**: Negro casi puro (#0F0F1E)

### Tipografía
- **Headings**: Space Grotesk Bold
- **Body**: Space Grotesk Regular
- **Mono**: Courier (para código)

### Componentes Reutilizables
- GlassCard (glassmorphism)
- GradientButton (botones con gradiente)
- AnimatedStatusIndicator (indicador de estado)
- ProgressRing (anillo de progreso)
- CustomSearchField (búsqueda)
- EmptyState (estado vacío)
- TagChip (etiquetas)

## Permisos Requeridos

### Android
\`\`\`xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
\`\`\`

### iOS
\`\`\`xml
<key>NSMicrophoneUsageDescription</key>
<string>Necesitamos acceso al micrófono para usar comandos de voz</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Necesitamos acceso a la red local</string>
\`\`\`

## Contacto & Soporte

- **Desarrollador**: Duvan
- **Email**: tu@email.com
- **Portfolio**: axchisan.com
- **GitHub**: @duvan

## Licencia

Este proyecto es privado y de uso personal. Todos los derechos reservados.

---

**¡Hecho con 💜 para la presentación de el SENA**
