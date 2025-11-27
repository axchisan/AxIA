import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../services/api_service.dart';

class RoutineProvider extends ChangeNotifier {
  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _error;
  final ApiService _apiService = ApiService();

  List<Routine> get routines => _routines;
  List<Routine> get todayRoutines => _routines.where((r) => !r.isCompleted).toList();
  List<Routine> get completedRoutines => _routines.where((r) => r.isCompleted).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  RoutineProvider() {
    loadRoutines();
  }

  Future<void> loadRoutines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final routinesData = await _apiService.getRoutines();
      _routines = routinesData.map((data) {
        return Routine(
          id: data['id'].toString(),
          name: data['name'] ?? '',
          category: data['category'] ?? 'general',
          icon: data['icon'] ?? '📋',
          duration: Duration(minutes: data['duration_minutes'] ?? 60),
          description: data['description'] ?? '',
          streak: data['streak'] ?? 0,
          isCompleted: data['is_completed'] ?? false,
        );
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading routines: $e';
      _isLoading = false;
      _loadMockData();
      notifyListeners();
    }
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

  Future<void> toggleRoutine(String routineId) async {
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index != -1) {
      final routine = _routines[index];
      final newCompletedStatus = !routine.isCompleted;
      
      // Optimistic update
      _routines[index] = Routine(
        id: routine.id,
        name: routine.name,
        category: routine.category,
        icon: routine.icon,
        duration: routine.duration,
        description: routine.description,
        isCompleted: newCompletedStatus,
        completedAt: newCompletedStatus ? DateTime.now() : null,
        streak: routine.streak + (newCompletedStatus ? 1 : 0),
      );
      notifyListeners();
      
      // Update API
      try {
        await _apiService.updateRoutine(
          int.parse(routineId),
          {
            'is_completed': newCompletedStatus,
            'streak': routine.streak + (newCompletedStatus ? 1 : 0),
          },
        );
      } catch (e) {
        // Revert on error
        _routines[index] = routine;
        _error = 'Failed to update routine';
        notifyListeners();
      }
    }
  }

  Future<void> addRoutine(Routine routine) async {
    try {
      final result = await _apiService.createRoutine({
        'name': routine.name,
        'description': routine.description,
        'icon': routine.icon,
        'duration_minutes': routine.duration.inMinutes,
        'category': routine.category,
        'scheduled_days': [],
      });
      
      final newRoutine = Routine(
        id: result['id'].toString(),
        name: result['name'],
        category: result['category'] ?? routine.category,
        icon: result['icon'] ?? routine.icon,
        duration: Duration(minutes: result['duration_minutes'] ?? 60),
        description: result['description'] ?? routine.description,
        streak: result['streak'] ?? 0,
        isCompleted: result['is_completed'] ?? false,
      );
      
      _routines.add(newRoutine);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add routine';
      notifyListeners();
    }
  }

  Future<void> updateRoutine(String routineId, Routine updatedRoutine) async {
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index != -1) {
      final oldRoutine = _routines[index];
      
      // Optimistic update
      _routines[index] = updatedRoutine;
      notifyListeners();
      
      try {
        await _apiService.updateRoutine(
          int.parse(routineId),
          {
            'name': updatedRoutine.name,
            'description': updatedRoutine.description,
            'icon': updatedRoutine.icon,
            'duration_minutes': updatedRoutine.duration.inMinutes,
            'category': updatedRoutine.category,
            'is_completed': updatedRoutine.isCompleted,
            'streak': updatedRoutine.streak,
          },
        );
      } catch (e) {
        // Revert on error
        _routines[index] = oldRoutine;
        _error = 'Failed to update routine';
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index != -1) {
      final routine = _routines[index];
      
      // Optimistic delete
      _routines.removeAt(index);
      notifyListeners();
      
      try {
        await _apiService.deleteRoutine(int.parse(routineId));
      } catch (e) {
        // Revert on error
        _routines.insert(index, routine);
        _error = 'Failed to delete routine';
        notifyListeners();
      }
    }
  }
}
