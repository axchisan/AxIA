import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class TasksProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch tasks
  Future<void> fetchTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _apiService.getTasks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create task
  Future<void> createTask(String title, String description, String dueDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final task = await _apiService.createTask(title, description, dueDate);
      _tasks.add(task);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle task completion
  Future<void> toggleTask(String taskId) async {
    try {
      final taskIndex = _tasks.indexWhere((t) => t['id'] == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex]['completed'] = !_tasks[taskIndex]['completed'];
        await _apiService.updateTask(taskId, {'completed': _tasks[taskIndex]['completed']});
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      _tasks.removeWhere((t) => t['id'] == taskId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
