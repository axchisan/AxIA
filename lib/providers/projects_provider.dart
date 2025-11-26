import 'package:flutter/foundation.dart';
import '../models/project.dart';

class ProjectsProvider extends ChangeNotifier {
  List<Project> _projects = [];

  List<Project> get projects => _projects;
  List<Project> get activeProjects => _projects.where((p) => p.status == 'active').toList();

  ProjectsProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    _projects = [
      Project(
        id: '1',
        name: 'AxIA Mobile App',
        description: 'Aplicación móvil de control personal',
        clientId: 'self',
        progress: 0.65,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        dueDate: DateTime.now().add(const Duration(days: 20)),
        status: 'active',
        technologies: ['Flutter', 'FastAPI', 'PostgreSQL'],
      ),
      Project(
        id: '2',
        name: 'Website Redesign',
        description: 'Rediseño de axchisan.com',
        clientId: 'client1',
        progress: 0.45,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        status: 'active',
        technologies: ['Next.js', 'TypeScript', 'Tailwind'],
      ),
    ];
    notifyListeners();
  }

  void updateProject(String projectId, Project updatedProject) {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      _projects[index] = updatedProject;
      notifyListeners();
    }
  }

  void addProject(Project project) {
    _projects.add(project);
    notifyListeners();
  }
}
