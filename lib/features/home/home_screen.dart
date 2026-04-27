import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/linear_search_bar.dart';
import 'home_provider.dart';
import 'widgets/screenshot_card.dart';
import 'widgets/tag_filter_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(notifier: notifier, isImporting: state.isImporting),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearSearchBar(
                hint: 'Search screenshots...',
                onChanged: notifier.setSearch,
              ),
            ),
            const SizedBox(height: 10),
            TagFilterBar(
              selected: state.tagFilter,
              onSelected: notifier.setFilter,
            ),
            if (state.isImporting) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                minHeight: 1,
                backgroundColor: AppColors.borderSubtle,
                color: AppColors.accent,
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: state.screenshots.isEmpty
                  ? EmptyState(
                      icon: Icons.screenshot_monitor_outlined,
                      title: state.searchQuery.isNotEmpty
                          ? 'No results'
                          : 'No screenshots yet',
                      subtitle: state.searchQuery.isNotEmpty
                          ? 'Try a different search term'
                          : 'Import screenshots using the button above',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: state.screenshots.length,
                      itemBuilder: (context, i) {
                        final s = state.screenshots[i];
                        return ScreenshotCard(
                          screenshot: s,
                          onTap: () =>
                              context.push('/screenshot/${s.id}'),
                          onDelete: () =>
                              notifier.deleteScreenshot(s.id!),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final HomeNotifier notifier;
  final bool isImporting;

  const _Header({required this.notifier, required this.isImporting});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RecallOS', style: AppTypography.displayMd),
              const SizedBox(height: 2),
              Text('Your visual memory',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
          const Spacer(),
          _ImportButton(notifier: notifier, isImporting: isImporting),
        ],
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  final HomeNotifier notifier;
  final bool isImporting;

  const _ImportButton({required this.notifier, required this.isImporting});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isImporting ? null : () => _showImportOptions(context),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppColors.borderDefault, width: 1),
        ),
        child: isImporting
            ? const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.accent,
                  ),
                ),
              )
            : const Icon(Icons.add_rounded,
                color: AppColors.textSecondary, size: 18),
      ),
    );
  }

  void _showImportOptions(BuildContext context) {
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
            const SizedBox(height: 8),
            _SheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Import from gallery',
              onTap: () {
                Navigator.pop(context);
                notifier.importFromGallery();
              },
            ),
            _SheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a photo',
              onTap: () {
                Navigator.pop(context);
                notifier.importFromCamera();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption({
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
                style:
                    AppTypography.bodyMd.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
