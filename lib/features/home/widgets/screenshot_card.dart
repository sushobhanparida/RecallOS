import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/models/screenshot_model.dart';
import '../../../shared/widgets/tag_badge.dart';

class ScreenshotCard extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ScreenshotCard({
    super.key,
    required this.screenshot,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDefault, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            Expanded(
              child: _ScreenshotImage(uri: screenshot.uri),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
              ),
              child: Row(
                children: [
                  TagBadge(tag: screenshot.tag, compact: true),
                  const Spacer(),
                  Text(
                    _formatDate(screenshot.createdAt),
                    style: AppTypography.monoSm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
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
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return CachedNetworkImage(
      imageUrl: uri,
      fit: BoxFit.cover,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.bgElevated,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: AppColors.textMuted, size: 24),
        ),
      );
}
