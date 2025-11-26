import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../models/presence_status.dart';
import '../../providers/presence_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';

class PresenceScreen extends StatelessWidget {
  const PresenceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Presencia'),
      ),
      body: Consumer<PresenceProvider>(
        builder: (context, presenceProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentStatus(presenceProvider),
                const SizedBox(height: 32),
                _buildStatusOptions(context, presenceProvider),
                const SizedBox(height: 32),
                _buildCustomMessage(context, presenceProvider),
                const SizedBox(height: 32),
                _buildStatusInfo(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStatus(PresenceProvider provider) {
    final status = provider.status;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(status).withOpacity(0.2),
              border: Border.all(
                color: _getStatusColor(status),
                width: 3,
              ),
            ),
            child: Icon(
              _getStatusIcon(status),
              size: 40,
              color: _getStatusColor(status),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            provider.statusLabel,
            style: AppTypography.h2.copyWith(
              color: AppColors.textDarkPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.customMessage.isEmpty
                ? 'Establece un mensaje de estado'
                : provider.customMessage,
            style: AppTypography.body2.copyWith(
              color: AppColors.textDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOptions(BuildContext context, PresenceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cambiar Estado',
          style: AppTypography.body1.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...PresenceStatus.values.map((status) {
          final isSelected = provider.status == status;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => provider.setStatus(status),
              child: GlassCard(
                backgroundColor: isSelected
                    ? _getStatusColor(status).withOpacity(0.2)
                    : AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? _getStatusColor(status)
                      : AppColors.neonPurple.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStatusColor(status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.name[0].toUpperCase() +
                                status.name.substring(1),
                            style: AppTypography.body1.copyWith(
                              color: AppColors.textDarkPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getStatusDescription(status),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textDarkTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: _getStatusColor(status),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCustomMessage(
    BuildContext context,
    PresenceProvider provider,
  ) {
    final controller = TextEditingController(text: provider.customMessage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mensaje Personalizado',
          style: AppTypography.body1.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 3,
          style: AppTypography.body2.copyWith(
            color: AppColors.textDarkPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Ej: Estoy en una reunión, volveré en 1 hora',
            hintStyle: AppTypography.body2.copyWith(
              color: AppColors.textDarkTertiary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.neonPurple.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.neonPurple,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 12),
        GradientButton(
          label: 'Guardar Mensaje',
          onPressed: () {
            provider.setCustomMessage(controller.text);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Mensaje actualizado'),
                backgroundColor: AppColors.statusAvailable,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Significado de Estados',
          style: AppTypography.body1.copyWith(
            color: AppColors.textDarkPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          ('Disponible', 'Puedo recibir mensajes y llamadas'),
          ('Enfoque', 'En modo trabajo profundo, responderé después'),
          ('Ausente', 'No estoy disponible en este momento'),
          ('Ocupado', 'Urgencias solo, no interrumpir'),
        ]
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.neonPurple,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textDarkPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            item.$2,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textDarkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
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

  IconData _getStatusIcon(PresenceStatus status) {
    switch (status) {
      case PresenceStatus.available:
        return Icons.check_circle_rounded;
      case PresenceStatus.focus:
        return Icons.auto_awesome_rounded;
      case PresenceStatus.away:
        return Icons.schedule_rounded;
      case PresenceStatus.busy:
        return Icons.do_not_disturb_rounded;
    }
  }

  String _getStatusDescription(PresenceStatus status) {
    switch (status) {
      case PresenceStatus.available:
        return 'Disponible para mensajes y llamadas';
      case PresenceStatus.focus:
        return 'En modo trabajo profundo';
      case PresenceStatus.away:
        return 'No disponible en este momento';
      case PresenceStatus.busy:
        return 'Urgencias solo, no interrumpir';
    }
  }
}
