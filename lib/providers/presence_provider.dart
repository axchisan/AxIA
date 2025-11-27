import 'dart:ui';

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
  Timer? _inactiveCounterTimer;
  final ApiService _apiService = ApiService();

  PresenceStatus get status => _status;
  String get customMessage => _customMessage;
  bool get isOnline => _isOnline;
  DateTime? get lastActive => _lastActive;
  int get inactiveMinutes => _inactiveMinutes;
  
  String get statusLabel => _status.name[0].toUpperCase() + _status.name.substring(1);
  
  String get formattedInactiveTime {
    if (_inactiveMinutes < 60) {
      return '$_inactiveMinutes min';
    } else if (_inactiveMinutes < 1440) {
      final hours = _inactiveMinutes ~/ 60;
      final minutes = _inactiveMinutes % 60;
      return '${hours}h ${minutes}min';
    } else {
      final days = _inactiveMinutes ~/ 1440;
      final hours = (_inactiveMinutes % 1440) ~/ 60;
      return '${days}d ${hours}h';
    }
  }

  PresenceProvider() {
    loadPresence();
    _startHeartbeat();
    _startInactiveCounter();
  }

  Future<void> loadPresence() async {
    try {
      final data = await _apiService.getPresence();
      _isOnline = data['is_online'] ?? false;
      _status = _parseStatus(data['status'] ?? 'available');
      _customMessage = data['custom_message'] ?? '';
      
      if (data['last_active'] != null) {
        _lastActive = DateTime.parse(data['last_active']);
        // Calculate inactive minutes
        final now = DateTime.now();
        final difference = now.difference(_lastActive!);
        _inactiveMinutes = difference.inMinutes;
      }
      
      notifyListeners();
    } catch (e) {
      // Use defaults on error
      debugPrint('Error loading presence: $e');
    }
  }

  Future<void> setStatus(PresenceStatus newStatus) async {
    final oldStatus = _status;
    
    // Optimistic update
    _status = newStatus;
    _isOnline = true;
    _lastActive = DateTime.now();
    _inactiveMinutes = 0;
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
      debugPrint('Error setting status: $e');
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
      debugPrint('Error setting custom message: $e');
    }
  }

  Future<void> setInactiveTime(int minutes) async {
    if (minutes < 0) {
      debugPrint('Invalid minutes value: $minutes');
      return;
    }

    _inactiveMinutes = minutes.clamp(0, 525600); // Max 1 year in minutes
    
    if (minutes == 0) {
      _lastActive = DateTime.now();
      _isOnline = true;
    } else {
      final now = DateTime.now();
      final subtract = Duration(minutes: minutes);
      _lastActive = now.subtract(subtract);
      _isOnline = false;
    }
    
    notifyListeners();
    
    // Update on server
    try {
      await _apiService.updatePresence(_status.name, _customMessage.isNotEmpty ? _customMessage : null);
    } catch (e) {
      debugPrint('Error updating inactive time: $e');
    }
  }

  Future<void> markAsOnline() async {
    _isOnline = true;
    _lastActive = DateTime.now();
    _inactiveMinutes = 0;
    notifyListeners();
    
    try {
      await _apiService.updatePresence(_status.name, _customMessage.isNotEmpty ? _customMessage : null);
    } catch (e) {
      debugPrint('Error marking as online: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_isOnline) {
        _apiService.sendPresenceHeartbeat();
      }
    });
  }

  void _startInactiveCounter() {
    _inactiveCounterTimer?.cancel();
    _inactiveCounterTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_isOnline && _lastActive != null) {
        final now = DateTime.now();
        final difference = now.difference(_lastActive!);
        _inactiveMinutes = difference.inMinutes;
        notifyListeners();
      }
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

  Color getStatusColor() {
    // This would ideally use your AppColors, but keeping it flexible
    switch (_status) {
      case PresenceStatus.available:
        return const Color(0xFF10B981); // AppColors.statusAvailable
      case PresenceStatus.focus:
        return const Color(0xFFF59E0B); // AppColors.statusFocus
      case PresenceStatus.away:
        return const Color(0xFF9CA3AF); // AppColors.statusAway
      case PresenceStatus.busy:
        return const Color(0xFFEF4444); // AppColors.statusBusy
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _inactiveCounterTimer?.cancel();
    super.dispose();
  }
}
