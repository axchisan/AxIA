import 'package:flutter/foundation.dart';
import '../models/presence_status.dart';

class PresenceProvider extends ChangeNotifier {
  PresenceStatus _status = PresenceStatus.available;
  String _customMessage = '';

  PresenceStatus get status => _status;
  String get customMessage => _customMessage;
  
  String get statusLabel => _status.name[0].toUpperCase() + _status.name.substring(1);

  void setStatus(PresenceStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void setCustomMessage(String message) {
    _customMessage = message;
    notifyListeners();
  }

  String getStatusEmoji() {
    switch (_status) {
      case PresenceStatus.available:
        return '🟢';
      case PresenceStatus.focus:
        return '🟡';
      case PresenceStatus.away:
        return '⚪';
      case PresenceStatus.busy:
        return '🔴';
    }
  }
}
