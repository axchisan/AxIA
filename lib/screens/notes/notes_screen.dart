import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../providers/notes_provider.dart';
import '../../models/note.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/custom_search_field.dart';
import '../../widgets/common/empty_state.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Notas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showNoteDialog(context),
          ),
        ],
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, _) {
          if (notesProvider.isLoading && notesProvider.notes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredNotes = notesProvider.notes
              .where((note) =>
                  note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  note.content
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
              .toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomSearchField(
                    hintText: 'Buscar notas...',
                    onChanged: (value) => setState(() => _searchQuery = value),
                    leadingIcon: Icons.search_rounded,
                  ),
                  const SizedBox(height: 24),
                  if (notesProvider.pinnedNotes.isNotEmpty) ...[
                    Text(
                      'Fijadas',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.neonPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildNotesList(
                      notesProvider.pinnedNotes,
                      notesProvider,
                      context,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (filteredNotes.isNotEmpty)
                    Text(
                      'Todas las Notas',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (notesProvider.pinnedNotes.isEmpty)
                    EmptyState(
                      title: 'Sin notas',
                      description: 'Comienza creando tu primera nota privada',
                      icon: Icons.note_outlined,
                      buttonLabel: 'Nueva Nota',
                      onButtonPressed: () => _showNoteDialog(context),
                    ),
                  const SizedBox(height: 12),
                  ..._buildNotesList(
                    filteredNotes.where((n) => !n.isPinned).toList(),
                    notesProvider,
                    context,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteDialog(context),
        backgroundColor: AppColors.neonPurple,
        label: const Text('Nueva Nota'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  List<Widget> _buildNotesList(
    List<Note> notes,
    NotesProvider provider,
    BuildContext context,
  ) {
    return notes.map<Widget>((note) {
      final color = _parseColor(note.color ?? '#7C3AED');
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _showNoteDialog(context, note: note),
          child: GlassCard(
            backgroundColor: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textDarkPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            note.isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            color: color,
                            size: 20,
                          ),
                          onPressed: () => provider.togglePin(note.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.statusBusy,
                            size: 20,
                          ),
                          onPressed: () => _confirmDelete(context, provider, note),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textDarkSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 6,
                      children: note.tags
                          .take(3)
                          .map<Widget>(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: AppTypography.caption.copyWith(
                                  color: color,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    Text(
                      '${note.updatedAt.day}/${note.updatedAt.month}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDarkTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showNoteDialog(BuildContext context, {Note? note}) {
    final isEdit = note != null;
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    String selectedColor = note?.color ?? '#7C3AED';
    List<String> tags = note?.tags ?? [];
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Editar Nota' : 'Nueva Nota'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Contenido *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Color:', style: AppTypography.body2),
                    const SizedBox(width: 12),
                    ...[
                      '#7C3AED', // Purple
                      '#10B981', // Green
                      '#F59E0B', // Yellow
                      '#EF4444', // Red
                      '#3B82F6', // Blue
                    ].map((colorHex) {
                      final color = _parseColor(colorHex);
                      final isSelected = selectedColor == colorHex;
                      
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = colorHex),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.textDarkPrimary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        decoration: const InputDecoration(
                          labelText: 'Agregar etiqueta',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              tags.add(value);
                              tagController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (tagController.text.isNotEmpty) {
                          setState(() {
                            tags.add(tagController.text);
                            tagController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() => tags.remove(tag));
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Título y contenido son requeridos')),
                  );
                  return;
                }

                final provider = Provider.of<NotesProvider>(context, listen: false);

                try {
                  if (isEdit) {
                    final updatedNote = Note(
                      id: note.id,
                      title: titleController.text,
                      content: contentController.text,
                      createdAt: note.createdAt,
                      updatedAt: DateTime.now(),
                      color: selectedColor,
                      tags: tags,
                      isPinned: note.isPinned,
                    );
                    
                    await provider.updateNote(note.id, updatedNote);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nota actualizada')),
                    );
                  } else {
                    final newNote = Note(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      content: contentController.text,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      color: selectedColor,
                      tags: tags,
                      isPinned: false,
                    );
                    
                    await provider.addNote(newNote);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nota creada')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text(isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, NotesProvider provider, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Nota'),
        content: Text('¿Estás seguro de eliminar "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.deleteNote(note.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nota eliminada')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: AppColors.statusBusy),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorHex) {
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }
}
