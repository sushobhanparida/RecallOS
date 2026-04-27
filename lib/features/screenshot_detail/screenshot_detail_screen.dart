import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/models/screenshot_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/tag_badge.dart';

final _screenshotDetailProvider =
    FutureProvider.family<Screenshot?, int>((ref, id) async {
  return AppDatabase.instance.getScreenshotById(id);
});

class ScreenshotDetailScreen extends ConsumerWidget {
  final int screenshotId;

  const ScreenshotDetailScreen({super.key, required this.screenshotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_screenshotDetailProvider(screenshotId));

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.accent,
          ),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: AppTypography.bodyMd.copyWith(color: AppColors.error)),
        ),
        data: (screenshot) {
          if (screenshot == null) {
            return Center(
              child: Text('Not found',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.textMuted)),
            );
          }
          return _DetailView(screenshot: screenshot);
        },
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final Screenshot screenshot;

  const _DetailView({required this.screenshot});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.height * 0.45,
          pinned: true,
          backgroundColor: AppColors.bgBase,
          surfaceTintColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _HeroImage(uri: screenshot.uri),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag
                _DetailRow(
                  icon: Icons.sell_outlined,
                  label: 'Category',
                  child: TagBadge(tag: screenshot.tag),
                ),
                _divider(),
                // Date
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Captured',
                  child: Text(
                    DateFormat('MMM d, yyyy · HH:mm')
                        .format(screenshot.createdAt),
                    style: AppTypography.monoMd,
                  ),
                ),
                if (screenshot.extractedText.isNotEmpty) ...[
                  _divider(),
                  _ExtractedTextSection(text: screenshot.extractedText),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: AppColors.borderSubtle, height: 1),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 16),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.textMuted)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ExtractedTextSection extends StatefulWidget {
  final String text;
  const _ExtractedTextSection({required this.text});

  @override
  State<_ExtractedTextSection> createState() => _ExtractedTextSectionState();
}

class _ExtractedTextSectionState extends State<_ExtractedTextSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_snippet_outlined,
                  color: AppColors.textMuted, size: 16),
              const SizedBox(width: 12),
              Text('Extracted text',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.textMuted)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.accentText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDefault, width: 1),
              ),
              child: Text(
                widget.text,
                style: AppTypography.monoMd,
              ),
            ),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDefault, width: 1),
              ),
              child: Text(
                widget.text.length > 200
                    ? '${widget.text.substring(0, 200)}…'
                    : widget.text,
                style: AppTypography.monoMd,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String uri;
  const _HeroImage({required this.uri});

  @override
  Widget build(BuildContext context) {
    final isLocal = !uri.startsWith('http');
    if (isLocal) {
      return Image.file(
        File(uri),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(color: AppColors.bgSurface),
      );
    }
    return Image.network(
      uri,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Container(color: AppColors.bgSurface),
    );
  }
}
