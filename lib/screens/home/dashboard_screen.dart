import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/progress_ring.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/presence_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().fetchTasks();
      context.read<CalendarProvider>().fetchEvents(
        timeMin: DateTime.now(),
        timeMax: DateTime.now().add(const Duration(days: 7)),
      );
      context.read<NotesProvider>().loadNotes();
      context.read<RoutineProvider>().loadRoutines();
      context.read<PresenceProvider>().loadPresence();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM', 'es_ES');
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(
              dateFormat.format(DateTime.now()),
              style: AppTypography.caption.copyWith(
                color: AppColors.textDarkSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPresenceCard(),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildTasksOverview(),
              const SizedBox(height: 24),
              _buildUpcomingEvents(),
              const SizedBox(height: 24),
              _buildRoutineProgress(),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresenceCard() {
    return Consumer<PresenceProvider>(
      builder: (context, presence, _) {
        return GlassCard(
          padding: const EdgeInsets.all(20),
          backgroundColor: presence.getStatusColor().withOpacity(0.12),
          border: Border.all(
            color: presence.getStatusColor().withOpacity(0.3),
            width: 1.5,
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: presence.getStatusColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: presence.getStatusColor().withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presence.statusLabel,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textDarkPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      presence.isOnline
                          ? 'Activo ahora'
                          : 'Inactivo por ${presence.formattedInactiveTime}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (presence.customMessage.isNotEmpty)
                Tooltip(
                  message: presence.customMessage,
                  child: Icon(
                    Icons.message_outlined,
                    color: presence.getStatusColor(),
                    size: 20,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return Consumer4<TasksProvider, CalendarProvider, NotesProvider, RoutineProvider>(
      builder: (context, tasks, calendar, notes, routines, _) {
        final activeTasks = tasks.activeTasks.length;
        final todayEvents = calendar.getEventsForDay(DateTime.now()).length;
        final totalNotes = notes.notes.length;
        final completedRoutines = routines.completedRoutines.length;
        final totalRoutines = routines.routines.length;
        
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Tareas Activas',
              activeTasks.toString(),
              Icons.check_circle_outline_rounded,
              AppColors.neonPurple,
            ),
            _buildStatCard(
              'Eventos Hoy',
              todayEvents.toString(),
              Icons.event_rounded,
              AppColors.statusAvailable,
            ),
            _buildStatCard(
              'Notas',
              totalNotes.toString(),
              Icons.note_outlined,
              AppColors.statusFocus,
            ),
            _buildStatCard(
              'Rutinas',
              '$completedRoutines/$totalRoutines',
              Icons.event_repeat_rounded,
              AppColors.statusAvailable,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              color: AppColors.textDarkPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTasksOverview() {
    return Consumer<TasksProvider>(
      builder: (context, tasksProvider, _) {
        final activeTasks = tasksProvider.activeTasks;
        final completedTasks = tasksProvider.completedTasks;
        final total = activeTasks.length + completedTasks.length;
        final progress = total > 0 ? completedTasks.length / total : 0.0;

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso de Tareas',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/tasks');
                    },
                    child: const Text('Ver Todas'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ProgressRing(
                    progress: progress,
                    size: 80,
                    label: '${(progress * 100).toInt()}%',
                    progressColor: AppColors.statusAvailable,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressRow(
                          'Completadas',
                          completedTasks.length,
                          AppColors.statusAvailable,
                        ),
                        const SizedBox(height: 8),
                        _buildProgressRow(
                          'Pendientes',
                          activeTasks.length,
                          AppColors.statusFocus,
                        ),
                        const SizedBox(height: 8),
                        _buildProgressRow(
                          'Total',
                          total,
                          AppColors.neonPurple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (activeTasks.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Próximas Tareas',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textDarkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...activeTasks.take(3).map((task) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: AppColors.neonPurple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textDarkPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textDarkSecondary,
              ),
            ),
          ],
        ),
        Text(
          count.toString(),
          style: AppTypography.body2.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents() {
    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, _) {
        final now = DateTime.now();
        final todayEvents = calendarProvider.getEventsForDay(now);
        final upcomingEvents = calendarProvider.events
            .where((e) => e.startTime.isAfter(now))
            .take(3)
            .toList();

        if (todayEvents.isEmpty && upcomingEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Próximos Eventos',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/calendar');
                    },
                    child: const Text('Ver Calendario'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (todayEvents.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusAvailable.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.statusAvailable.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.today_rounded,
                        color: AppColors.statusAvailable,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${todayEvents.length} evento${todayEvents.length > 1 ? 's' : ''} hoy',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textDarkPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ...upcomingEvents.map((event) {
                final timeFormat = DateFormat('dd MMM, HH:mm');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textDarkPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeFormat.format(event.startTime),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textDarkTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutineProgress() {
    return Consumer<RoutineProvider>(
      builder: (context, routineProvider, _) {
        if (routineProvider.routines.isEmpty) {
          return const SizedBox.shrink();
        }

        final completed = routineProvider.completedRoutines.length;
        final total = routineProvider.routines.length;
        final progress = total > 0 ? completed / total : 0.0;

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rutinas de Hoy',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/routines');
                    },
                    child: const Text('Ver Todas'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.bgDarkSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.statusAvailable,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Text(
                '$completed de $total completadas',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textDarkSecondary,
                ),
              ),
              if (routineProvider.todayRoutines.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...routineProvider.todayRoutines.take(3).map((routine) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(routine.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            routine.name,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textDarkPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${routine.duration.inMinutes} min',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textDarkTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: AppTypography.body1.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          children: [
            _buildActionCard(
              'Nueva Nota',
              Icons.note_add_outlined,
              AppColors.statusFocus,
              () => Navigator.pushNamed(context, '/notes'),
            ),
            _buildActionCard(
              'Nueva Tarea',
              Icons.add_task_rounded,
              AppColors.neonPurple,
              () => Navigator.pushNamed(context, '/tasks'),
            ),
            _buildActionCard(
              'Nuevo Evento',
              Icons.event_outlined,
              AppColors.statusAvailable,
              () => Navigator.pushNamed(context, '/calendar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        backgroundColor: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textDarkPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
