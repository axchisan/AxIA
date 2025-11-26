import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final String label;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  const ProgressRing({
    Key? key,
    required this.progress,
    this.size = 100,
    required this.label,
    this.progressColor = AppColors.neonPurple,
    this.backgroundColor = AppColors.bgDarkCard,
    this.strokeWidth = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              backgroundColor: backgroundColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTypography.h3.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textDarkTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
