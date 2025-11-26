import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;
  final bool showViewAll;

  const SectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.onViewAll,
    this.showViewAll = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.body1.copyWith(
                color: AppColors.textDarkPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textDarkSecondary,
                ),
              ),
            ],
          ],
        ),
        if (showViewAll && onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver Todo',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neonPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.neonPurple,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
