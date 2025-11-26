import 'package:flutter/material.dart';

class AnimatedStatusIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final bool animate;

  const AnimatedStatusIndicator({
    Key? key,
    required this.color,
    this.size = 12,
    this.animate = true,
  }) : super(key: key);

  @override
  State<AnimatedStatusIndicator> createState() =>
      _AnimatedStatusIndicatorState();
}

class _AnimatedStatusIndicatorState extends State<AnimatedStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation =
        Tween<double>(begin: 1, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(
            0.5 + (_animationController.value * 0.5),
          ),
        ),
      ),
    );
  }
}
