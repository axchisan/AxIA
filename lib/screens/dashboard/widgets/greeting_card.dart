import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';

class GreetingCard extends StatelessWidget {
  final AnimationController animationController;

  const GreetingCard({
    Key? key,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Buenos días';
      if (hour < 18) return 'Buenas tardes';
      return 'Buenas noches';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryViolet.withOpacity(0.8),
              AppColors.primaryDeep.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.neonPurple.withOpacity(0.3),
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getGreeting(),
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Duvan • Desarrollador & Emprendedor',
                  style: AppTypography.body2.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'Tareas Hoy',
                        value: '4',
                        icon: Icons.task_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Mensajes',
                        value: '12',
                        icon: Icons.mail_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.h3.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.caption.copyWith(color: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }
}
