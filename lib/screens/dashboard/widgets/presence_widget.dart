import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../models/presence_status.dart';
import '../../../providers/presence_provider.dart';

class PresenceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PresenceProvider>(
      builder: (context, presenceProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgDarkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.neonPurple.withOpacity(0.2),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mi Presencia',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(presenceProvider.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(presenceProvider.status),
                      ),
                    ),
                    child: Text(
                      presenceProvider.statusLabel,
                      style: AppTypography.caption.copyWith(
                        color: _getStatusColor(presenceProvider.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: PresenceStatus.values.map((status) {
                    final isSelected = presenceProvider.status == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => presenceProvider.setStatus(status),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getStatusColor(status).withOpacity(0.2)
                                : AppColors.bgDarkSecondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? _getStatusColor(status)
                                  : AppColors.textDarkTertiary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getStatusColor(status),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                status.name[0].toUpperCase() + status.name.substring(1),
                                style: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? _getStatusColor(status)
                                      : AppColors.textDarkSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                style: AppTypography.body2.copyWith(color: AppColors.textDarkPrimary),
                decoration: InputDecoration(
                  hintText: 'Mensaje de ausencia...',
                  hintStyle: AppTypography.body2.copyWith(
                    color: AppColors.textDarkTertiary,
                  ),
                  prefixIcon: Icon(Icons.edit_rounded, color: AppColors.neonPurple),
                  suffixIcon: Icon(Icons.send_rounded, color: AppColors.neonPurple),
                ),
                onChanged: (value) => presenceProvider.setCustomMessage(value),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(PresenceStatus status) {
    switch (status) {
      case PresenceStatus.available:
        return AppColors.statusAvailable;
      case PresenceStatus.focus:
        return AppColors.statusFocus;
      case PresenceStatus.away:
        return AppColors.statusAway;
      case PresenceStatus.busy:
        return AppColors.statusBusy;
    }
  }
}
