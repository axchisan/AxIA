import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../providers/routine_provider.dart';

class QuickRoutines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineProvider>(
      builder: (context, routineProvider, _) {
        final routines = routineProvider.todayRoutines;
        return Column(
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
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Ver Todo',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neonPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => routineProvider.toggleRoutine(routine.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgDarkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.neonPurple.withOpacity(0.2),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Checkbox(
                            value: routine.isCompleted,
                            onChanged: (_) => routineProvider.toggleRoutine(routine.id),
                            activeColor: AppColors.statusAvailable,
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
              },
            ),
          ],
        );
      },
    );
  }
}
