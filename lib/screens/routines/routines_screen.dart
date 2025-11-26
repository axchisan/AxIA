import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../providers/routine_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/progress_ring.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rutinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<RoutineProvider>(
        builder: (context, routineProvider, _) {
          final completed = routineProvider.completedRoutines.length;
          final total = routineProvider.routines.length;
          final progress = total > 0 ? completed / total : 0.0;

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
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
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
              '¡Excelente trabajo! 🎉',
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
        Text(
          'Pendientes',
          style: AppTypography.body1.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...routineProvider.todayRoutines.map((routine) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => routineProvider.toggleRoutine(routine.id),
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
                      onChanged: (_) =>
                          routineProvider.toggleRoutine(routine.id),
                      fillColor: MaterialStateProperty.all(
                        AppColors.statusAvailable,
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
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                backgroundColor: AppColors.statusAvailable.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusAvailable.withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.statusAvailable,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        routine.name,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textDarkPrimary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}
