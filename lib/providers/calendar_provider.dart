import 'package:flutter/foundation.dart';
import '../models/calendar_event.dart';
import '../services/api_service.dart';

class CalendarProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CalendarEvent> _events = [];
  Map<DateTime, List<CalendarEvent>> _eventsByDate = {};
  bool _isLoading = false;
  String? _error;

  List<CalendarEvent> get events => _events;
  Map<DateTime, List<CalendarEvent>> get eventsByDate => _eventsByDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch calendar events
  Future<void> fetchEvents({DateTime? timeMin, DateTime? timeMax}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _apiService.getCalendarEvents(
        timeMin: timeMin,
        timeMax: timeMax,
      );
      
      // Group events by date
      _eventsByDate = {};
      for (var event in _events) {
        final date = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );
        
        if (_eventsByDate[date] == null) {
          _eventsByDate[date] = [];
        }
        _eventsByDate[date]!.add(event);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get events for a specific day
  List<CalendarEvent> getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _eventsByDate[date] ?? [];
  }

  // Add event
  Future<void> createEvent({
    required String summary,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    try {
      final event = await _apiService.createCalendarEvent(
        summary: summary,
        startTime: startTime,
        endTime: endTime,
        description: description,
        location: location,
      );
      
      _events.add(event);
      
      // Update events by date
      final date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      
      if (_eventsByDate[date] == null) {
        _eventsByDate[date] = [];
      }
      _eventsByDate[date]!.add(event);
      
      notifyListeners();
    } catch (e) {
      _error = 'Error creating event: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _apiService.deleteCalendarEvent(eventId);
      
      // Remove from events list
      final event = _events.firstWhere((e) => e.id == eventId);
      _events.removeWhere((e) => e.id == eventId);
      
      // Remove from events by date
      final date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      
      _eventsByDate[date]?.removeWhere((e) => e.id == eventId);
      
      notifyListeners();
    } catch (e) {
      _error = 'Error deleting event: $e';
      notifyListeners();
      rethrow;
    }
  }
}
