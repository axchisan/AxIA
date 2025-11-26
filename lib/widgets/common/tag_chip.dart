import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';

class TagChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool removable;

  const TagChip({
    Key? key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.onRemove,
    this.removable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.bgDarkCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.neonPurple.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: textColor ?? AppColors.textDarkPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (removable) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: textColor ?? AppColors.textDarkPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
