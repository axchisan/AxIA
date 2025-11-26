import 'package:flutter/foundation.dart';
import '../models/note.dart';

class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];

  List<Note> get notes => _notes;
  List<Note> get pinnedNotes => _notes.where((n) => n.isPinned).toList();

  NotesProvider() {
    _loadMockData();
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

  void addNote(Note note) {
    _notes.add(note);
    notifyListeners();
  }

  void updateNote(String noteId, Note updatedNote) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }
  }

  void deleteNote(String noteId) {
    _notes.removeWhere((n) => n.id == noteId);
    notifyListeners();
  }

  void togglePin(String noteId) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      final note = _notes[index];
      _notes[index] = Note(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        color: note.color,
        tags: note.tags,
        isPinned: !note.isPinned,
      );
      notifyListeners();
    }
  }
}
