import 'package:flutter/foundation.dart';
import '../models/routine.dart';

class RoutineProvider extends ChangeNotifier {
  List<Routine> _routines = [];

  List<Routine> get routines => _routines;
  List<Routine> get todayRoutines => _routines.where((r) => !r.isCompleted).toList();
  List<Routine> get completedRoutines => _routines.where((r) => r.isCompleted).toList();

  RoutineProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    _routines = [
      Routine(
        id: '1',
        name: 'Karate Training',
        category: 'karate',
        icon: '🥋',
        duration: const Duration(hours: 1, minutes: 30),
        description: 'Entrenamiento diario',
        streak: 45,
      ),
      Routine(
        id: '2',
        name: 'Coding Session',
        category: 'code',
        icon: '💻',
        duration: const Duration(hours: 3),
        description: 'Desarrollo de AxIA',
        streak: 30,
      ),
      Routine(
        id: '3',
        name: 'English Learning',
        category: 'english',
        icon: '🌍',
        duration: const Duration(minutes: 45),
        description: 'Practicar inglés',
        streak: 25,
      ),
      Routine(
        id: '4',
        name: 'Meditation',
        category: 'meditation',
        icon: '🧘',
        duration: const Duration(minutes: 20),
        description: 'Mindfulness',
        streak: 15,
      ),
    ];
    notifyListeners();
  }

  void toggleRoutine(String routineId) {
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index != -1) {
      final routine = _routines[index];
      _routines[index] = Routine(
        id: routine.id,
        name: routine.name,
        category: routine.category,
        icon: routine.icon,
        duration: routine.duration,
        description: routine.description,
        isCompleted: !routine.isCompleted,
        completedAt: !routine.isCompleted ? DateTime.now() : null,
        streak: routine.streak + (!routine.isCompleted ? 1 : 0),
      );
      notifyListeners();
    }
  }

  void addRoutine(Routine routine) {
    _routines.add(routine);
    notifyListeners();
  }
}
