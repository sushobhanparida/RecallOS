import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/models/screenshot_model.dart';

class ScreenshotCard extends StatefulWidget {
  final Screenshot screenshot;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToTasks;
  final VoidCallback? onAddToStack;

  const ScreenshotCard({
    super.key,
    required this.screenshot,
    required this.onTap,
    this.onDelete,
    this.onAddToTasks,
    this.onAddToStack,
  });

  @override
  State<ScreenshotCard> createState() => _ScreenshotCardState();
}

class _ScreenshotCardState extends State<ScreenshotCard> {
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _loadAspectRatio();
  }

  @override
  void didUpdateWidget(covariant ScreenshotCard old) {
    super.didUpdateWidget(old);
    if (old.screenshot.uri != widget.screenshot.uri) {
      setState(() => _aspectRatio = null);
      _loadAspectRatio();
    }
  }

  void _loadAspectRatio() {
    final uri = widget.screenshot.uri;
    final ImageProvider provider = uri.startsWith('http')
        ? NetworkImage(uri) as ImageProvider
        : FileImage(File(uri));

    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _aspectRatio = info.image.width / info.image.height;
        });
      }
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _aspectRatio ?? (9.0 / 16.0);
    return AspectRatio(
      aspectRatio: ratio,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress:
            (widget.onAddToTasks != null || widget.onAddToStack != null)
                ? () => _showQuickActions(context)
                : null,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDefault, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: _ScreenshotImage(uri: widget.screenshot.uri),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    final addToTasksFn = widget.onAddToTasks;
    final addToStackFn = widget.onAddToStack;
    if (addToTasksFn == null && addToStackFn == null) return;
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
                widget.onTap();
              },
            ),
            _QuickAction(
              icon: Icons.playlist_add_rounded,
              label: 'Add to Tasks',
              onTap: () {
                Navigator.pop(context);
                addToTasksFn?.call();
              },
            ),
            _QuickAction(
              icon: Icons.layers_rounded,
              label: 'Add to Stack',
              onTap: () {
                Navigator.pop(context);
                addToStackFn?.call();
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
        color: AppColors.bgSurface,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: AppColors.textMuted, size: 20),
        ),
      );
}
