import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../models/presence_status.dart';
import '../../../providers/presence_provider.dart';

class PresenceWidget extends StatefulWidget {
  @override
  State<PresenceWidget> createState() => _PresenceWidgetState();
}

class _PresenceWidgetState extends State<PresenceWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final presenceProvider = Provider.of<PresenceProvider>(context, listen: false);
      presenceProvider.loadPresence();
    });
  }

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mi Presencia',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textDarkPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (presenceProvider.inactiveMinutes > 0)
                        Text(
                          'Inactivo: ${presenceProvider.formattedInactiveTime}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(presenceProvider.isOnline).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(presenceProvider.isOnline),
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
                            color: _getStatusColor(presenceProvider.isOnline),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          presenceProvider.isOnline ? 'Online' : 'Offline',
                          style: AppTypography.caption.copyWith(
                            color: _getStatusColor(presenceProvider.isOnline),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/presence');
                },
                icon: Icon(Icons.settings_rounded, size: 18),
                label: Text('Gestionar Estado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(bool isOnline) {
    return isOnline ? AppColors.statusAvailable : AppColors.statusAway;
  }
}
