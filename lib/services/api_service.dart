import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/calendar_event.dart';
import '../models/google_task.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get calendar events from FastAPI
  Future<List<CalendarEvent>> getCalendarEvents({
    DateTime? timeMin,
    DateTime? timeMax,
  }) async {
    try {
      final headers = await _getHeaders();
      String url = '${ApiConfig.baseUrl}/calendar/events';
      
      final queryParams = <String, String>{};
      if (timeMin != null) {
        queryParams['time_min'] = timeMin.toIso8601String();
      }
      if (timeMax != null) {
        queryParams['time_max'] = timeMax.toIso8601String();
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load calendar events');
      }
    } catch (e) {
      throw Exception('Error fetching calendar: $e');
    }
  }

  Future<CalendarEvent> createCalendarEvent({
    required String summary,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/calendar/events'),
        headers: headers,
        body: jsonEncode({
          'summary': summary,
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'description': description,
          'location': location,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CalendarEvent.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create event');
      }
    } catch (e) {
      throw Exception('Error creating event: $e');
    }
  }

  Future<void> deleteCalendarEvent(String eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/calendar/events/$eventId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete event');
      }
    } catch (e) {
      throw Exception('Error deleting event: $e');
    }
  }

  // Get tasks from FastAPI
  Future<List<GoogleTask>> getGoogleTasks({bool showCompleted = true}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/google/tasks?show_completed=$showCompleted'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => GoogleTask.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  Future<GoogleTask> createGoogleTask({
    required String title,
    String? notes,
    DateTime? due,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/google/tasks'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'notes': notes,
          'due': due?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return GoogleTask.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create task');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<void> toggleGoogleTask(String taskId, bool completed) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/google/tasks/$taskId'),
        headers: headers,
        body: jsonEncode({
          'completed': completed,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle task');
      }
    } catch (e) {
      throw Exception('Error toggling task: $e');
    }
  }

  Future<void> deleteGoogleTask(String taskId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/google/tasks/$taskId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete task');
      }
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }

  // Create new task
  Future<Map<String, dynamic>> createTask(String title, String description, String dueDate) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tasksEndpoint}'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'due_date': dueDate,
          'completed': false,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to create task');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  // Update task
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tasksEndpoint}/$taskId'),
        headers: headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update task');
      }
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  // Message history
  Future<List<Map<String, dynamic>>> getMessageHistory(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.messagesHistoryEndpoint}/$sessionId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load message history');
      }
    } catch (e) {
      throw Exception('Error fetching message history: $e');
    }
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.healthEndpoint}'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getRoutines() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/routines'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to load routines');
      }
    } catch (e) {
      throw Exception('Error fetching routines: $e');
    }
  }

  Future<Map<String, dynamic>> createRoutine(Map<String, dynamic> routineData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/routines'),
        headers: headers,
        body: jsonEncode(routineData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create routine');
      }
    } catch (e) {
      throw Exception('Error creating routine: $e');
    }
  }

  Future<Map<String, dynamic>> updateRoutine(int routineId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/routines/$routineId'),
        headers: headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update routine');
      }
    } catch (e) {
      throw Exception('Error updating routine: $e');
    }
  }

  Future<void> deleteRoutine(int routineId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/routines/$routineId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete routine');
      }
    } catch (e) {
      throw Exception('Error deleting routine: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to load notes');
      }
    } catch (e) {
      throw Exception('Error fetching notes: $e');
    }
  }

  Future<Map<String, dynamic>> createNote(Map<String, dynamic> noteData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notes'),
        headers: headers,
        body: jsonEncode(noteData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create note');
      }
    } catch (e) {
      throw Exception('Error creating note: $e');
    }
  }

  Future<Map<String, dynamic>> updateNote(int noteId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notes/$noteId'),
        headers: headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update note');
      }
    } catch (e) {
      throw Exception('Error updating note: $e');
    }
  }

  Future<void> deleteNote(int noteId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/notes/$noteId'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete note');
      }
    } catch (e) {
      throw Exception('Error deleting note: $e');
    }
  }

  Future<Map<String, dynamic>> getPresence() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/presence'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load presence');
      }
    } catch (e) {
      throw Exception('Error fetching presence: $e');
    }
  }

  Future<void> updatePresence(String status, String? customMessage) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/presence/update'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          'custom_message': customMessage,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update presence');
      }
    } catch (e) {
      throw Exception('Error updating presence: $e');
    }
  }

  Future<void> sendPresenceHeartbeat() async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/presence/heartbeat'),
        headers: headers,
      );
    } catch (e) {
      // Silent fail for heartbeat
    }
  }
}
