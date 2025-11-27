import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        title: const Text('Mi Actividad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              Provider.of<PresenceProvider>(context, listen: false).loadPresence();
            },
          ),
        ],
      ),
      body: Consumer<PresenceProvider>(
        builder: (context, presenceProvider, _) {
          return RefreshIndicator(
            onRefresh: () => presenceProvider.loadPresence(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentStatus(presenceProvider),
                  const SizedBox(height: 24),
                  _buildActivityTimer(context, presenceProvider),
                  const SizedBox(height: 24),
                  _buildStatusOptions(context, presenceProvider),
                  const SizedBox(height: 24),
                  _buildCustomMessage(context, presenceProvider),
                  const SizedBox(height: 24),
                  _buildStatusInfo(),
                  const SizedBox(height: 24),
                  _buildChatbotInfo(),
                ],
              ),
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(status).withOpacity(0.2),
              border: Border.all(
                color: _getStatusColor(status),
                width: 4,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 48,
                  color: _getStatusColor(status),
                ),
                if (provider.isOnline)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.statusAvailable,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            provider.statusLabel,
            style: AppTypography.h2.copyWith(
              color: AppColors.textDarkPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: provider.isOnline
                  ? AppColors.statusAvailable.withOpacity(0.2)
                  : AppColors.statusAway.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              provider.isOnline ? 'EN LÍNEA' : 'AUSENTE',
              style: AppTypography.caption.copyWith(
                color: provider.isOnline
                    ? AppColors.statusAvailable
                    : AppColors.statusAway,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (provider.customMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              provider.customMessage,
              style: AppTypography.body2.copyWith(
                color: AppColors.textDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTimer(BuildContext context, PresenceProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiempo de Inactividad',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Controla cuándo AxIA responde por ti',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.timer_outlined,
                color: AppColors.neonPurple,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: provider.isOnline
                  ? AppColors.statusAvailable.withOpacity(0.1)
                  : AppColors.statusAway.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: provider.isOnline
                    ? AppColors.statusAvailable.withOpacity(0.3)
                    : AppColors.statusAway.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  provider.formattedInactiveTime,
                  style: AppTypography.h1.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.isOnline ? 'Activo ahora' : 'Inactivo',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Marcar como Online',
                  onPressed: provider.isOnline
                      ? () {}
                      : provider.markAsOnline,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showInactiveTimeDialog(context, provider),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar Tiempo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.neonPurple),
                    foregroundColor: AppColors.neonPurple,
                  ),
                ),
              ),
            ],
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

  Widget _buildChatbotInfo() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: AppColors.neonPurple.withOpacity(0.1),
      border: Border.all(color: AppColors.neonPurple.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: AppColors.neonPurple,
              ),
              const SizedBox(width: 12),
              Text(
                'Chatbot AxIA',
                style: AppTypography.body1.copyWith(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cuando estás inactivo, el chatbot de AxIA responderá automáticamente a tus mensajes de WhatsApp según tu estado de actividad.',
            style: AppTypography.body2.copyWith(
              color: AppColors.textDarkSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDarkSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: AppColors.statusFocus,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Marca como "Online" cuando estés activo para pausar las respuestas automáticas',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textDarkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInactiveTimeDialog(BuildContext context, PresenceProvider provider) {
    final controller = TextEditingController(
      text: provider.inactiveMinutes.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Tiempo de Inactividad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa el tiempo de inactividad en minutos:',
              style: AppTypography.body2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Minutos',
                border: const OutlineInputBorder(),
                suffixText: 'min',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.text = '30';
                    },
                    child: const Text('30 min'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.text = '60';
                    },
                    child: const Text('1 hora'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.text = '120';
                    },
                    child: const Text('2 horas'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text) ?? 0;
              provider.setInactiveTime(minutes);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tiempo de inactividad actualizado'),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
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
