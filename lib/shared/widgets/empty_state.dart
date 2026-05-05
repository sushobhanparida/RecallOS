import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDefault, width: 1),
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 22),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: AppTypography.headingSm
                    .copyWith(color: AppColors.textSecondary)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
