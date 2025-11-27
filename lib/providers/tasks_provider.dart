// ignore_for_file: unused_local_variable

import 'package:flutter/foundation.dart';
import '../models/google_task.dart';
import '../services/api_service.dart';

class TasksProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<GoogleTask> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<GoogleTask> get tasks => _tasks;
  List<GoogleTask> get activeTasks => _tasks.where((t) => !t.completed).toList();
  List<GoogleTask> get completedTasks => _tasks.where((t) => t.completed).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch tasks
  Future<void> fetchTasks({bool showCompleted = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _apiService.getGoogleTasks(showCompleted: showCompleted);
      
      // Sort: active tasks first, then by due date
      _tasks.sort((a, b) {
        if (a.completed != b.completed) {
          return a.completed ? 1 : -1;
        }
        if (a.due == null && b.due == null) return 0;
        if (a.due == null) return 1;
        if (b.due == null) return -1;
        return a.due!.compareTo(b.due!);
      });
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create task
  Future<void> createTask({
    required String title,
    String? notes,
    DateTime? due,
  }) async {
    try {
      final task = await _apiService.createGoogleTask(
        title: title,
        notes: notes,
        due: due,
      );
      
      _tasks.insert(0, task);
      notifyListeners();
    } catch (e) {
      _error = 'Error creating task: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Toggle task completion
  Future<void> toggleTask(String taskId) async {
    try {
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        final newCompleted = !task.completed;
        
        // Optimistic update
        _tasks[taskIndex] = GoogleTask(
          id: task.id,
          title: task.title,
          notes: task.notes,
          completed: newCompleted,
          status: newCompleted ? 'completed' : 'needsAction',
          due: task.due,
          updated: task.updated,
        );
        notifyListeners();
        
        await _apiService.toggleGoogleTask(taskId, newCompleted);
      }
    } catch (e) {
      _error = 'Error toggling task: $e';
      notifyListeners();
      // Revert on error
      await fetchTasks();
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      // Optimistic delete
      final task = _tasks.firstWhere((t) => t.id == taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      
      await _apiService.deleteGoogleTask(taskId);
    } catch (e) {
      _error = 'Error deleting task: $e';
      notifyListeners();
      // Revert on error
      await fetchTasks();
    }
  }
}
