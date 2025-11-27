import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/presence_status.dart';
import '../services/api_service.dart';

class PresenceProvider extends ChangeNotifier {
  PresenceStatus _status = PresenceStatus.available;
  String _customMessage = '';
  bool _isOnline = false;
  DateTime? _lastActive;
  int _inactiveMinutes = 0;
  Timer? _heartbeatTimer;
  final ApiService _apiService = ApiService();

  PresenceStatus get status => _status;
  String get customMessage => _customMessage;
  bool get isOnline => _isOnline;
  DateTime? get lastActive => _lastActive;
  int get inactiveMinutes => _inactiveMinutes;
  
  String get statusLabel => _status.name[0].toUpperCase() + _status.name.substring(1);

  PresenceProvider() {
    loadPresence();
    _startHeartbeat();
  }

  Future<void> loadPresence() async {
    try {
      final data = await _apiService.getPresence();
      _isOnline = data['is_online'] ?? false;
      _status = _parseStatus(data['status'] ?? 'available');
      _customMessage = data['custom_message'] ?? '';
      _lastActive = DateTime.parse(data['last_active']);
      _inactiveMinutes = data['inactive_minutes'] ?? 0;
      notifyListeners();
    } catch (e) {
      // Use defaults on error
    }
  }

  Future<void> setStatus(PresenceStatus newStatus) async {
    final oldStatus = _status;
    
    // Optimistic update
    _status = newStatus;
    notifyListeners();
    
    try {
      await _apiService.updatePresence(
        _status.name,
        _customMessage.isNotEmpty ? _customMessage : null,
      );
    } catch (e) {
      // Revert on error
      _status = oldStatus;
      notifyListeners();
    }
  }

  Future<void> setCustomMessage(String message) async {
    final oldMessage = _customMessage;
    
    // Optimistic update
    _customMessage = message;
    notifyListeners();
    
    try {
      await _apiService.updatePresence(_status.name, message.isNotEmpty ? message : null);
    } catch (e) {
      // Revert on error
      _customMessage = oldMessage;
      notifyListeners();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _apiService.sendPresenceHeartbeat();
    });
  }

  PresenceStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return PresenceStatus.available;
      case 'focus':
        return PresenceStatus.focus;
      case 'away':
        return PresenceStatus.away;
      case 'busy':
        return PresenceStatus.busy;
      default:
        return PresenceStatus.available;
    }
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

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
