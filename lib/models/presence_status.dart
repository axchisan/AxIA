enum PresenceStatus {
  available,
  focus,
  away,
  busy,
}

class PresenceModel {
  final PresenceStatus status;
  final String customMessage;
  final DateTime lastUpdate;

  PresenceModel({
    required this.status,
    required this.customMessage,
    required this.lastUpdate,
  });

  String get statusLabel => status.name[0].toUpperCase() + status.name.substring(1);
}
