import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';

class CustomSearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final IconData leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingIconTap;

  const CustomSearchField({
    Key? key,
    this.hintText = 'Buscar...',
    required this.onChanged,
    this.leadingIcon = Icons.search_rounded,
    this.trailingIcon,
    this.onTrailingIconTap,
  }) : super(key: key);

  @override
  State<CustomSearchField> createState() => _CustomSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgDarkSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFocused
                ? AppColors.neonPurple
                : AppColors.neonPurple.withOpacity(0.2),
            width: _isFocused ? 2 : 1,
          ),
        ),
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          style: AppTypography.body2.copyWith(
            color: AppColors.textDarkPrimary,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.hintText,
            hintStyle: AppTypography.body2.copyWith(
              color: AppColors.textDarkTertiary,
            ),
            prefixIcon: Icon(
              widget.leadingIcon,
              color: AppColors.neonPurple,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textDarkTertiary,
                    ),
                  )
                : widget.trailingIcon != null
                    ? GestureDetector(
                        onTap: widget.onTrailingIconTap,
                        child: Icon(
                          widget.trailingIcon,
                          color: AppColors.neonPurple,
                        ),
                      )
                    : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}
