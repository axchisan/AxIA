import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../providers/notes_provider.dart';
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
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, _) {
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
                  else
                    EmptyState(
                      title: 'Sin notas',
                      description: 'Comienza creando tu primera nota privada',
                      icon: Icons.note_outlined,
                      buttonLabel: 'Nueva Nota',
                      onButtonPressed: () {},
                    ),
                  const SizedBox(height: 12),
                  ..._buildNotesList(
                    filteredNotes,
                    notesProvider,
                    context,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildNotesList(
    List notes,
    dynamic provider,
    BuildContext context,
  ) {
    return notes.map<Widget>((note) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () {},
          child: GlassCard(
            backgroundColor: AppColors.bgDarkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neonPurple.withOpacity(0.2),
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
                    IconButton(
                      icon: Icon(
                        note.isPinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        color: AppColors.neonPurple,
                        size: 20,
                      ),
                      onPressed: () => provider.togglePin(note.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.content,
                  maxLines: 2,
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
                          .take(2)
                          .map<Widget>(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.neonPurple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.neonPurple,
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
}
