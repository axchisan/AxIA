class Routine {
  final String id;
  final String name;
  final String category; // karate, code, english, meditation, etc
  final String icon;
  final Duration duration;
  final String? description;
  final bool isCompleted;
  final DateTime? completedAt;
  final int streak;

  Routine({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.duration,
    this.description,
    this.isCompleted = false,
    this.completedAt,
    this.streak = 0,
  });
}
