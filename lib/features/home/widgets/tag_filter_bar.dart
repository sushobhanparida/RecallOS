import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/models/screenshot_model.dart';

class TagFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  static const _filters = [
    'All',
    'Notes',
    'Links',
    'QRs',
    'Events',
    'Shopping',
  ];

  const TagFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: _filters
            .map((f) => _FilterChip(
                  label: f,
                  selected: f == selected,
                  onTap: () => onSelected(f),
                  tag: f == 'All' ? null : _tagFor(f),
                ))
            .toList(),
      ),
    );
  }

  ScreenshotTag? _tagFor(String label) {
    switch (label) {
      case 'Notes':
        return ScreenshotTag.note;
      case 'Links':
        return ScreenshotTag.link;
      case 'QRs':
        return ScreenshotTag.qr;
      case 'Events':
        return ScreenshotTag.event;
      case 'Shopping':
        return ScreenshotTag.shopping;
    }
    return null;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ScreenshotTag? tag;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tag,
  });

  static Color _dotColor(ScreenshotTag? t) {
    if (t == null) return AppColors.accent;
    switch (t) {
      case ScreenshotTag.shopping:
        return AppColors.tagShopping;
      case ScreenshotTag.link:
        return AppColors.tagLink;
      case ScreenshotTag.event:
        return AppColors.tagEvent;
      case ScreenshotTag.note:
        return AppColors.tagNote;
      case ScreenshotTag.qr:
        return AppColors.tagQr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor(tag);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.bgOverlay : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? AppColors.borderEmphasis
                  : AppColors.borderDefault,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tag != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? dotColor : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  color:
                      selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
