import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/screenshot_model.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/empty_state.dart';

/// Vertical list of link-tagged screenshots. Each row shows a thumbnail
/// preview and the URLs detected in the screenshot as clickable chips.
/// Tapping the thumbnail opens the screenshot detail; tapping a URL chip
/// opens the link in the browser.
class LinksListView extends StatelessWidget {
  final List<Screenshot> screenshots;
  final ValueChanged<Screenshot> onOpen;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LinksListView({
    super.key,
    required this.screenshots,
    required this.onOpen,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (screenshots.isEmpty) {
      return const EmptyState(
        icon: Icons.link_rounded,
        title: 'No links yet',
        subtitle: 'Screenshots with URLs will show up here',
      );
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
      itemCount: screenshots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _LinkRow(
        screenshot: screenshots[i],
        onOpen: () => onOpen(screenshots[i]),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onOpen;

  const _LinkRow({required this.screenshot, required this.onOpen});

  List<String> _urls() {
    final fromEntities = screenshot.entities
        .where((e) => e.type == 'url' || e.type == 'qr_url')
        .map((e) => e.rawText)
        .toList();
    if (fromEntities.isNotEmpty) return fromEntities;
    // Fallback: scrape URLs out of OCR text if entity extraction missed.
    return RegExp(r'https?:\/\/[^\s]+')
        .allMatches(screenshot.extractedText)
        .map((m) => m.group(0)!)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          GestureDetector(
            onTap: onOpen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 88,
                child: _Thumb(uri: screenshot.uri),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (urls.isEmpty)
                  Text(
                    'No URLs detected',
                    style: AppTypography.labelMd
                        .copyWith(color: AppColors.textMuted),
                  )
                else
                  for (final url in urls.take(4)) ...[
                    _UrlChip(url: url),
                    const SizedBox(height: 6),
                  ],
                if (urls.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('+${urls.length - 4} more',
                        style: AppTypography.labelSm
                            .copyWith(color: AppColors.textMuted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlChip extends StatelessWidget {
  final String url;
  const _UrlChip({required this.url});

  String get _display {
    final u = Uri.tryParse(url);
    if (u == null) return url;
    var host = u.host.isEmpty ? url : u.host;
    if (host.startsWith('www.')) host = host.substring(4);
    final pathTail = u.path.isEmpty || u.path == '/' ? '' : u.path;
    return '$host$pathTail';
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.tagLinkMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.tagLink.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded,
                size: 12, color: AppColors.tagLink),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _display,
                style: AppTypography.monoSm
                    .copyWith(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new_rounded,
                size: 12, color: AppColors.tagLink),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String uri;
  const _Thumb({required this.uri});

  @override
  Widget build(BuildContext context) {
    if (uri.startsWith('http')) {
      return Image.network(uri,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: AppColors.bgElevated));
    }
    return Image.file(File(uri),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: AppColors.bgElevated));
  }
}
