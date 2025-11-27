import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/api_service.dart';

class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;
  final ApiService _apiService = ApiService();

  List<Note> get notes => _notes;
  List<Note> get pinnedNotes => _notes.where((n) => n.isPinned).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  NotesProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final notesData = await _apiService.getNotes();
      _notes = notesData.map((data) {
        return Note(
          id: data['id'].toString(),
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          createdAt: DateTime.parse(data['created_at']),
          updatedAt: DateTime.parse(data['updated_at']),
          color: data['color'] ?? '#7C3AED',
          tags: List<String>.from(data['tags'] ?? []),
          isPinned: data['is_pinned'] ?? false,
        );
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading notes: $e';
      _isLoading = false;
      _loadMockData();
      notifyListeners();
    }
  }

  void _loadMockData() {
    _notes = [
      Note(
        id: '1',
        title: 'Ideas para AxIA',
        content: 'Implementar detección de emoción en voz...',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        color: '#7C3AED',
        tags: ['features', 'ai'],
        isPinned: true,
      ),
      Note(
        id: '2',
        title: 'Clientes Activos',
        content: 'Proyectos en curso de axchisan.com',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        tags: ['work', 'clients'],
        isPinned: false,
      ),
    ];
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    try {
      final result = await _apiService.createNote({
        'title': note.title,
        'content': note.content,
        'tags': note.tags,
        'is_pinned': note.isPinned,
        'color': note.color,
      });
      
      final newNote = Note(
        id: result['id'].toString(),
        title: result['title'],
        content: result['content'],
        createdAt: DateTime.parse(result['created_at']),
        updatedAt: DateTime.parse(result['updated_at']),
        color: result['color'] ?? '#7C3AED',
        tags: List<String>.from(result['tags'] ?? []),
        isPinned: result['is_pinned'] ?? false,
      );
      
      _notes.insert(0, newNote);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add note';
      notifyListeners();
    }
  }

  Future<void> updateNote(String noteId, Note updatedNote) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      final oldNote = _notes[index];
      
      // Optimistic update
      _notes[index] = updatedNote;
      notifyListeners();
      
      try {
        await _apiService.updateNote(
          int.parse(noteId),
          {
            'title': updatedNote.title,
            'content': updatedNote.content,
            'tags': updatedNote.tags,
            'is_pinned': updatedNote.isPinned,
            'color': updatedNote.color,
          },
        );
      } catch (e) {
        // Revert on error
        _notes[index] = oldNote;
        _error = 'Failed to update note';
        notifyListeners();
      }
    }
  }

  Future<void> deleteNote(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      final note = _notes[index];
      
      // Optimistic delete
      _notes.removeAt(index);
      notifyListeners();
      
      try {
        await _apiService.deleteNote(int.parse(noteId));
      } catch (e) {
        // Revert on error
        _notes.insert(index, note);
        _error = 'Failed to delete note';
        notifyListeners();
      }
    }
  }

  Future<void> togglePin(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      final note = _notes[index];
      final newNote = Note(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        color: note.color,
        tags: note.tags,
        isPinned: !note.isPinned,
      );
      
      // Optimistic update
      _notes[index] = newNote;
      notifyListeners();
      
      try {
        await _apiService.updateNote(
          int.parse(noteId),
          {'is_pinned': !note.isPinned},
        );
      } catch (e) {
        // Revert on error
        _notes[index] = note;
        _error = 'Failed to toggle pin';
        notifyListeners();
      }
    }
  }
}
