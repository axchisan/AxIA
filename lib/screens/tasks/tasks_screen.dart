import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../providers/tasks_provider.dart';
import '../../models/google_task.dart';
import '../../widgets/common/glass_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _showCompleted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TasksProvider>(context, listen: false)
          .fetchTasks(showCompleted: _showCompleted);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: Icon(
              _showCompleted
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            onPressed: () {
              setState(() => _showCompleted = !_showCompleted);
              Provider.of<TasksProvider>(context, listen: false)
                  .fetchTasks(showCompleted: _showCompleted);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              Provider.of<TasksProvider>(context, listen: false)
                  .fetchTasks(showCompleted: _showCompleted);
            },
          ),
        ],
      ),
      body: Consumer<TasksProvider>(
        builder: (context, tasksProvider, _) {
          if (tasksProvider.isLoading && tasksProvider.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeTasks = tasksProvider.activeTasks;
          final completedTasks = tasksProvider.completedTasks;

          return RefreshIndicator(
            onRefresh: () =>
                tasksProvider.fetchTasks(showCompleted: _showCompleted),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatistics(activeTasks, completedTasks),
                  const SizedBox(height: 24),
                  if (activeTasks.isNotEmpty) ...[
                    Text(
                      'Pendientes',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...activeTasks.map((task) => _buildTaskCard(task)),
                  ],
                  if (completedTasks.isNotEmpty && _showCompleted) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Completadas',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.statusAvailable,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...completedTasks.map((task) => _buildTaskCard(task)),
                  ],
                  if (activeTasks.isEmpty && completedTasks.isEmpty)
                    _buildEmptyState(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(context),
        backgroundColor: AppColors.neonPurple,
        label: const Text('Nueva Tarea'),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildStatistics(List<GoogleTask> active, List<GoogleTask> completed) {
    final total = active.length + completed.length;
    final progress = total > 0 ? completed.length / total : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            total.toString(),
            Icons.list_alt_rounded,
            AppColors.neonPurple,
          ),
          _buildStatItem(
            'Pendientes',
            active.length.toString(),
            Icons.radio_button_unchecked_rounded,
            AppColors.statusFocus,
          ),
          _buildStatItem(
            'Completadas',
            completed.length.toString(),
            Icons.check_circle_rounded,
            AppColors.statusAvailable,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.h2.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textDarkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(GoogleTask task) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isOverdue = task.due != null &&
        task.due!.isBefore(DateTime.now()) &&
        !task.completed;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      backgroundColor: task.completed
          ? AppColors.statusAvailable.withOpacity(0.1)
          : AppColors.bgDarkCard,
      border: Border.all(
        color: isOverdue
            ? AppColors.statusBusy
            : task.completed
                ? AppColors.statusAvailable.withOpacity(0.3)
                : AppColors.neonPurple.withOpacity(0.2),
        width: isOverdue ? 2 : 1,
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.completed,
            onChanged: (_) {
              Provider.of<TasksProvider>(context, listen: false)
                  .toggleTask(task.id);
            },
            fillColor: MaterialStateProperty.all(
              task.completed ? AppColors.statusAvailable : AppColors.neonPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.w600,
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.notes,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textDarkTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (task.due != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: isOverdue
                            ? AppColors.statusBusy
                            : AppColors.textDarkSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(task.due!),
                        style: AppTypography.caption.copyWith(
                          color: isOverdue
                              ? AppColors.statusBusy
                              : AppColors.textDarkSecondary,
                          fontWeight: isOverdue ? FontWeight.w600 : null,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Vencida',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.statusBusy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.statusBusy,
            ),
            onPressed: () => _confirmDelete(task),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 80,
              color: AppColors.textDarkTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin tareas',
              style: AppTypography.h3.copyWith(
                color: AppColors.textDarkPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera tarea para comenzar',
              style: AppTypography.body2.copyWith(
                color: AppColors.textDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nueva Tarea'),
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
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Fecha de vencimiento'),
                  subtitle: Text(
                    selectedDue != null
                        ? DateFormat('dd MMM yyyy').format(selectedDue!)
                        : 'Sin fecha',
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDue = date);
                    }
                  },
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
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El título es requerido')),
                  );
                  return;
                }

                try {
                  await Provider.of<TasksProvider>(context, listen: false)
                      .createTask(
                    title: titleController.text,
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                    due: selectedDue,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarea creada exitosamente')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(GoogleTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: Text('¿Estás seguro de eliminar "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Provider.of<TasksProvider>(context, listen: false)
                    .deleteTask(task.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tarea eliminada')),
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
