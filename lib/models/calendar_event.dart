class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? status;
  final String? htmlLink;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.status,
    this.htmlLink,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sin título',
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: DateTime.parse(json['end_time']).toLocal(),
      location: json['location'],
      status: json['status'],
      htmlLink: json['html_link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'status': status,
      'html_link': htmlLink,
    };
  }
}
