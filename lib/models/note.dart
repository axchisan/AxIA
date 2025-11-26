class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? color;
  final List<String> tags;
  final bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.tags = const [],
    this.isPinned = false,
  });
}
