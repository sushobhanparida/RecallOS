import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/models/stack_model.dart' as stack_model;

class StackCard extends StatelessWidget {
  final stack_model.Stack stack;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;

  const StackCard({
    super.key,
    required this.stack,
    required this.onTap,
    this.onDelete,
    this.onRename,
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
            // Cover image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Cover(stack: stack),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Count badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${stack.screenshots.length}',
                        style: AppTypography.monoSm
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  // Menu button
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _showMenu(context),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_horiz_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Name footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                stack.name,
                style: AppTypography.labelLg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
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
            if (onRename != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: AppColors.textSecondary, size: 18),
                title: Text('Rename',
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  onRename!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 18),
                title: Text('Delete stack',
                    style:
                        AppTypography.bodyMd.copyWith(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final stack_model.Stack stack;
  const _Cover({required this.stack});

  @override
  Widget build(BuildContext context) {
    if (stack.coverImage == null) {
      return Container(
        color: AppColors.bgElevated,
        child: const Center(
          child: Icon(Icons.photo_library_outlined,
              color: AppColors.textMuted, size: 28),
        ),
      );
    }
    final uri = stack.coverImage!.uri;
    if (uri.startsWith('http')) {
      return Image.network(uri, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: AppColors.bgElevated));
    }
    return Image.file(File(uri), fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppColors.bgElevated));
  }
}
