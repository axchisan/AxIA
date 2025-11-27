import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../providers/routine_provider.dart';
import '../../models/routine.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/progress_ring.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({Key? key}) : super(key: key);

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoutineProvider>(context, listen: false).loadRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rutinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showRoutineDialog(context),
          ),
        ],
      ),
      body: Consumer<RoutineProvider>(
        builder: (context, routineProvider, _) {
          if (routineProvider.isLoading && routineProvider.routines.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final completed = routineProvider.completedRoutines.length;
          final total = routineProvider.routines.length;
          final progress = total > 0 ? completed / total : 0.0;

          if (total == 0) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressSection(progress, completed, total),
                  const SizedBox(height: 32),
                  _buildRoutinesList(context, routineProvider),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoutineDialog(context),
        backgroundColor: AppColors.neonPurple,
        label: const Text('Nueva Rutina'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildProgressSection(double progress, int completed, int total) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ProgressRing(
            progress: progress,
            size: 120,
            label: 'De Hoy',
            progressColor: AppColors.statusAvailable,
          ),
          const SizedBox(height: 16),
          Text(
            '$completed de $total rutinas completadas',
            style: AppTypography.body2.copyWith(
              color: AppColors.textDarkSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (progress == 1.0)
            Text(
              'Excelente trabajo!',
              style: AppTypography.body1.copyWith(
                color: AppColors.statusAvailable,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoutinesList(
    BuildContext context,
    RoutineProvider routineProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (routineProvider.todayRoutines.isNotEmpty) ...[
          Text(
            'Pendientes',
            style: AppTypography.body1.copyWith(
              color: AppColors.textDarkPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...routineProvider.todayRoutines.map((routine) {
            return _buildRoutineCard(context, routineProvider, routine);
          }).toList(),
        ],
        if (routineProvider.completedRoutines.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Completadas',
            style: AppTypography.body1.copyWith(
              color: AppColors.statusAvailable,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...routineProvider.completedRoutines.map((routine) {
            return _buildRoutineCard(context, routineProvider, routine);
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildRoutineCard(
    BuildContext context,
    RoutineProvider provider,
    Routine routine,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => provider.toggleRoutine(routine.id),
        onLongPress: () => _showRoutineDialog(context, routine: routine),
        child: GlassCard(
          backgroundColor: routine.isCompleted
              ? AppColors.statusAvailable.withOpacity(0.1)
              : AppColors.bgDarkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: routine.isCompleted
                ? AppColors.statusAvailable.withOpacity(0.3)
                : AppColors.neonPurple.withOpacity(0.2),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          child: Row(
            children: [
              Checkbox(
                value: routine.isCompleted,
                onChanged: (value) {
                  if (value != null) {
                    provider.toggleRoutine(routine.id);
                  }
                },
                fillColor: MaterialStateProperty.all(
                  routine.isCompleted
                      ? AppColors.statusAvailable
                      : AppColors.neonPurple,
                ),
                side: BorderSide(
                  color: AppColors.neonPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.w600,
                        decoration: routine.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${routine.duration.inHours}h ${routine.duration.inMinutes.remainder(60)}m • Racha: ${routine.streak}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDarkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                routine.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.statusBusy,
                ),
                onPressed: () => _confirmDelete(context, provider, routine),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_repeat_rounded,
              size: 80,
              color: AppColors.textDarkTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin rutinas',
              style: AppTypography.h3.copyWith(
                color: AppColors.textDarkPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera rutina para comenzar a desarrollar buenos hábitos',
              style: AppTypography.body2.copyWith(
                color: AppColors.textDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showRoutineDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Rutina'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPurple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoutineDialog(BuildContext context, {Routine? routine}) {
    final isEdit = routine != null;
    final nameController = TextEditingController(text: routine?.name ?? '');
    final descriptionController = TextEditingController(
      text: routine?.description ?? '',
    );
    String selectedIcon = routine?.icon ?? '🏃';
    int durationMinutes = routine?.duration.inMinutes ?? 30;

    final iconOptions = ['🏃', '📚', '💪', '🧘', '🎯', '✍️', '🎨', '🎵', '🌱', '☕'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Editar Rutina' : 'Nueva Rutina'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Icono:', style: AppTypography.body2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: iconOptions.map((icon) {
                          final isSelected = selectedIcon == icon;
                          return GestureDetector(
                            onTap: () => setState(() => selectedIcon = icon),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.neonPurple.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.neonPurple
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(icon, style: const TextStyle(fontSize: 24)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Duración:', style: AppTypography.body2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        value: durationMinutes.toDouble(),
                        min: 5,
                        max: 180,
                        divisions: 35,
                        label: '$durationMinutes min',
                        onChanged: (value) {
                          setState(() => durationMinutes = value.toInt());
                        },
                      ),
                    ),
                    Text('$durationMinutes min'),
                  ],
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es requerido')),
                  );
                  return;
                }

                final provider = Provider.of<RoutineProvider>(context, listen: false);

                try {
                  if (isEdit) {
                    final updatedRoutine = Routine(
                      id: routine.id,
                      name: nameController.text,
                      description: descriptionController.text,
                      icon: selectedIcon,
                      duration: Duration(minutes: durationMinutes),
                      streak: routine.streak,
                      isCompleted: routine.isCompleted, category: '',
                    );
                    
                    await provider.updateRoutine(routine.id, updatedRoutine);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rutina actualizada')),
                    );
                  } else {
                    final newRoutine = Routine(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      description: descriptionController.text,
                      icon: selectedIcon,
                      duration: Duration(minutes: durationMinutes),
                      streak: 0,
                      isCompleted: false, category: '',
                    );
                    
                    await provider.addRoutine(newRoutine);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rutina creada')),
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

  void _confirmDelete(BuildContext context, RoutineProvider provider, Routine routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rutina'),
        content: Text('¿Estás seguro de eliminar "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.deleteRoutine(routine.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rutina eliminada')),
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
}
