import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/models/screenshot_model.dart';

class TagBadge extends StatelessWidget {
  final ScreenshotTag tag;
  final bool compact;

  const TagBadge({super.key, required this.tag, this.compact = false});

  static Color _bg(ScreenshotTag t) {
    switch (t) {
      case ScreenshotTag.shopping:
        return AppColors.tagShoppingMuted;
      case ScreenshotTag.link:
        return AppColors.tagLinkMuted;
      case ScreenshotTag.event:
        return AppColors.tagEventMuted;
      case ScreenshotTag.read:
        return AppColors.tagReadMuted;
      case ScreenshotTag.general:
        return AppColors.tagGeneralMuted;
    }
  }

  static Color _dot(ScreenshotTag t) {
    switch (t) {
      case ScreenshotTag.shopping:
        return AppColors.tagShopping;
      case ScreenshotTag.link:
        return AppColors.tagLink;
      case ScreenshotTag.event:
        return AppColors.tagEvent;
      case ScreenshotTag.read:
        return AppColors.tagRead;
      case ScreenshotTag.general:
        return AppColors.tagGeneral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _dot(tag);
    final bgColor = _bg(tag);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dotColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            tag.label,
            style: (compact ? AppTypography.monoSm : AppTypography.labelSm)
                .copyWith(color: dotColor),
          ),
        ],
      ),
    );
  }
}
