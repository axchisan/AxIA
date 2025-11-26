import 'package:flutter/material.dart';
import 'dart:ui';
import '../../config/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double blur;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final Color? backgroundColor;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blur = 10,
    this.borderRadius,
    this.onTap,
    this.border,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.glassDark,
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: border ?? Border.all(
                color: AppColors.neonPurple.withOpacity(0.2),
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
