class Project {
  final String id;
  final String name;
  final String description;
  final String clientId;
  final double progress;
  final DateTime startDate;
  final DateTime? dueDate;
  final String status; // active, completed, paused
  final List<String> technologies;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.clientId,
    required this.progress,
    required this.startDate,
    this.dueDate,
    required this.status,
    this.technologies = const [],
  });
}

class Client {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? company;
  final String? avatar;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.company,
    this.avatar,
    required this.createdAt,
  });
}
