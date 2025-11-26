import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    this.buttonLabel,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgDarkCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.neonPurple.withOpacity(0.2),
              ),
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppColors.neonPurple,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.h3.copyWith(
              color: AppColors.textDarkPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTypography.body2.copyWith(
              color: AppColors.textDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonLabel != null && onButtonPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onButtonPressed,
              child: Text(buttonLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
