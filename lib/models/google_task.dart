class GoogleTask {
  final String id;
  final String title;
  final String notes;
  final bool completed;
  final String status;
  final DateTime? due;
  final DateTime? updated;

  GoogleTask({
    required this.id,
    required this.title,
    this.notes = '',
    required this.completed,
    required this.status,
    this.due,
    this.updated,
  });

  factory GoogleTask.fromJson(Map<String, dynamic> json) {
    return GoogleTask(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sin título',
      notes: json['notes'] ?? '',
      completed: json['completed'] ?? false,
      status: json['status'] ?? 'needsAction',
      due: json['due'] != null ? DateTime.parse(json['due']) : null,
      updated: json['updated'] != null ? DateTime.parse(json['updated']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'completed': completed,
      'status': status,
      'due': due?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }
}
