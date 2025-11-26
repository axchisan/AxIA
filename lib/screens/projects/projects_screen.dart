import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/common/glass_card.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Proyectos'),
      ),
      body: Consumer<ProjectsProvider>(
        builder: (context, projectsProvider, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildProjectsList(projectsProvider),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildProjectsList(dynamic provider) {
    return provider.activeProjects.map<Widget>((project) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: AppTypography.body1.copyWith(
                            color: AppColors.textDarkPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.description,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusAvailable.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.statusAvailable,
                      ),
                    ),
                    child: Text(
                      'Activo',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.statusAvailable,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: project.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.bgDarkSecondary,
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.neonPurple,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(project.progress * 100).toStringAsFixed(0)}% completado',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textDarkTertiary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: project.technologies
                    .map(
                      (tech) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.neonPurple.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          tech,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.neonPurple,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
