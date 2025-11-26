import '../models/chat_message.dart';
import '../models/routine.dart';
import '../models/note.dart';
import '../models/project.dart';

class MockDataService {
  static List<ChatMessage> getMockMessages() {
    return [
      ChatMessage(
        id: '1',
        content: 'Hola Duvan, soy AxIA. ¿Cómo puedo ayudarte hoy?',
        sender: MessageSender.axia,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        id: '2',
        content: 'Necesito recordar mis sesiones de karate esta semana',
        sender: MessageSender.user,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      ChatMessage(
        id: '3',
        content: 'Perfecto. He anotado tus sesiones: lunes, miércoles y viernes a las 6 PM',
        sender: MessageSender.axia,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ];
  }

  static List<Routine> getMockRoutines() {
    return [
      Routine(
        id: '1',
        name: 'Karate Training',
        category: 'karate',
        icon: '🥋',
        duration: const Duration(hours: 1, minutes: 30),
        description: 'Entrenamiento diario de karate',
        streak: 45,
      ),
      Routine(
        id: '2',
        name: 'Coding Session',
        category: 'code',
        icon: '💻',
        duration: const Duration(hours: 3),
        description: 'Desarrollo de AxIA y proyectos',
        streak: 30,
      ),
      Routine(
        id: '3',
        name: 'English Learning',
        category: 'english',
        icon: '🌍',
        duration: const Duration(minutes: 45),
        description: 'Practicar inglés diariamente',
        streak: 25,
      ),
      Routine(
        id: '4',
        name: 'Meditation',
        category: 'meditation',
        icon: '🧘',
        duration: const Duration(minutes: 20),
        description: 'Sesión de meditación y mindfulness',
        streak: 15,
      ),
    ];
  }

  static List<Note> getMockNotes() {
    return [
      Note(
        id: '1',
        title: 'Ideas para AxIA v2.0',
        content: 'Implementar detección de emoción en voz, integración con calendario, recordatorios inteligentes con IA',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        color: '#7C3AED',
        tags: ['features', 'ai', 'roadmap'],
        isPinned: true,
      ),
      Note(
        id: '2',
        title: 'Clientes Activos Q4 2024',
        content: 'Proyectos en curso: Website redesign, Mobile app, API integration',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        tags: ['work', 'clients', 'axchisan'],
        isPinned: false,
      ),
      Note(
        id: '3',
        title: 'Preparación Presentación',
        content: 'Diapositivas, demo en vivo, ejemplos de casos de uso, métricas de impacto',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        color: '#06B6D4',
        tags: ['universidad', 'presentacion'],
        isPinned: false,
      ),
    ];
  }

  static List<Project> getMockProjects() {
    return [
      Project(
        id: '1',
        name: 'AxIA Mobile App',
        description: 'Aplicación móvil de control personal - Centro de vida y trabajo',
        clientId: 'self',
        progress: 0.65,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        dueDate: DateTime.now().add(const Duration(days: 20)),
        status: 'active',
        technologies: ['Flutter', 'FastAPI', 'PostgreSQL', 'n8n'],
      ),
      Project(
        id: '2',
        name: 'axchisan.com Redesign',
        description: 'Rediseño completo del sitio web de negocio',
        clientId: 'client1',
        progress: 0.45,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        status: 'active',
        technologies: ['Next.js', 'TypeScript', 'Tailwind', 'Vercel'],
      ),
      Project(
        id: '3',
        name: 'AxIA Backend Optimization',
        description: 'Optimización del backend FastAPI para mejor rendimiento',
        clientId: 'self',
        progress: 0.85,
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        dueDate: DateTime.now().add(const Duration(days: 5)),
        status: 'active',
        technologies: ['FastAPI', 'Python', 'Redis', 'PostgreSQL'],
      ),
    ];
  }
}
