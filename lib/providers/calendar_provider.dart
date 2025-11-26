import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class CalendarProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch calendar events
  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _apiService.getCalendarEvents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add event (local for now)
  void addEvent(Map<String, dynamic> event) {
    _events.add(event);
    notifyListeners();
  }

  // Remove event
  void removeEvent(String eventId) {
    _events.removeWhere((event) => event['id'] == eventId);
    notifyListeners();
  }
}
