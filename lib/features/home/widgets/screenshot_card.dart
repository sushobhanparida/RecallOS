import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/models/screenshot_model.dart';

class ScreenshotCard extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToTasks;

  const ScreenshotCard({
    super.key,
    required this.screenshot,
    required this.onTap,
    this.onDelete,
    this.onAddToTasks,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onAddToTasks != null
          ? () => _showQuickActions(context)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _ScreenshotImage(uri: screenshot.uri),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    final addToTasksFn = onAddToTasks;
    if (addToTasksFn == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppColors.borderDefault, width: 1),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.borderEmphasis,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            _QuickAction(
              icon: Icons.open_in_full_rounded,
              label: 'Open',
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            _QuickAction(
              icon: Icons.playlist_add_rounded,
              label: 'Add to Tasks',
              onTap: () {
                Navigator.pop(context);
                addToTasksFn();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 14),
            Text(label,
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ScreenshotImage extends StatelessWidget {
  final String uri;
  const _ScreenshotImage({required this.uri});

  @override
  Widget build(BuildContext context) {
    final isLocal = !uri.startsWith('http');
    if (isLocal) {
      return Image.file(
        File(uri),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return CachedNetworkImage(
      imageUrl: uri,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.bgElevated,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: AppColors.textMuted, size: 20),
        ),
      );
}
