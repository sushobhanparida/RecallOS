import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

enum LinearButtonVariant { primary, secondary, ghost, destructive }

class LinearButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LinearButtonVariant variant;
  final bool isLoading;
  final bool small;

  const LinearButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = LinearButtonVariant.secondary,
    this.isLoading = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, borderColor) = switch (variant) {
      LinearButtonVariant.primary => (
          AppColors.accent,
          Colors.white,
          Colors.transparent
        ),
      LinearButtonVariant.secondary => (
          AppColors.bgSurface,
          AppColors.textPrimary,
          AppColors.borderDefault
        ),
      LinearButtonVariant.ghost => (
          Colors.transparent,
          AppColors.textSecondary,
          Colors.transparent
        ),
      LinearButtonVariant.destructive => (
          AppColors.errorMuted,
          AppColors.error,
          AppColors.error.withValues(alpha: 0.3)
        ),
    };

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 10 : 14,
          vertical: small ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: textColor,
                ),
              )
            else if (icon != null)
              Icon(icon, color: textColor, size: small ? 13 : 15),
            if ((icon != null || isLoading) && label.isNotEmpty)
              SizedBox(width: small ? 5 : 6),
            if (label.isNotEmpty)
              Text(
                label,
                style: (small ? AppTypography.labelMd : AppTypography.labelLg)
                    .copyWith(color: textColor),
              ),
          ],
        ),
      ),
    );
  }
}
