import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/app_colors.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.bgDarkSecondary,
      highlightColor: AppColors.bgDarkTertiary,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}
