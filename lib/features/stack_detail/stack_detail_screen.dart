import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/models/screenshot_model.dart';
import '../../core/models/stack_model.dart' as stack_model;
import '../../shared/widgets/empty_state.dart';
import '../stacks/stacks_provider.dart';

class StackDetailScreen extends ConsumerWidget {
  final int stackId;

  const StackDetailScreen({super.key, required this.stackId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stackAsync = ref.watch(stackDetailProvider(stackId));
    final allAsync = ref.watch(allScreenshotsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: stackAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.accent,
          ),
        ),
        error: (e, _) => Center(
            child: Text('Error',
                style: AppTypography.bodyMd.copyWith(color: AppColors.error))),
        data: (stack) {
          if (stack == null) {
            return const EmptyState(
                icon: Icons.layers_outlined, title: 'Stack not found');
          }
          return _StackDetailView(
            stack: stack,
            allScreenshots: allAsync.value ?? [],
            onAddScreenshot: (sId) =>
                ref.read(stacksProvider.notifier).addScreenshot(stackId, sId),
            onRemoveScreenshot: (sId) {
              ref
                  .read(stacksProvider.notifier)
                  .removeScreenshot(stackId, sId);
              ref.invalidate(stackDetailProvider(stackId));
            },
          );
        },
      ),
    );
  }
}

class _StackDetailView extends StatelessWidget {
  final stack_model.Stack stack;
  final List<Screenshot> allScreenshots;
  final void Function(int) onAddScreenshot;
  final void Function(int) onRemoveScreenshot;

  const _StackDetailView({
    required this.stack,
    required this.allScreenshots,
    required this.onAddScreenshot,
    required this.onRemoveScreenshot,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
                Expanded(
                  child: Text(
                    stack.name,
                    style: AppTypography.headingMd,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAddPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.borderDefault, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: AppColors.textSecondary, size: 14),
                        const SizedBox(width: 4),
                        Text('Add',
                            style: AppTypography.labelMd
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${stack.screenshots.length} screenshots',
                style:
                    AppTypography.bodySm.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Grid
          Expanded(
            child: stack.screenshots.isEmpty
                ? const EmptyState(
                    icon: Icons.photo_library_outlined,
                    title: 'This stack is empty',
                    subtitle: 'Tap Add to include screenshots',
                  )
                : GridView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: stack.screenshots.length,
                    itemBuilder: (context, i) {
                      final s = stack.screenshots[i];
                      return _GridItem(
                        screenshot: s,
                        onTap: () => context.push('/screenshot/${s.id}'),
                        onRemove: () => onRemoveScreenshot(s.id!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddPicker(BuildContext context) {
    final existing =
        stack.screenshots.map((s) => s.id!).toSet();
    final available =
        allScreenshots.where((s) => !existing.contains(s.id)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppColors.borderDefault, width: 1),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scrollCtrl) => _ScreenshotPicker(
          screenshots: available,
          scrollController: scrollCtrl,
          onSelect: (id) {
            onAddScreenshot(id);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _GridItem({
    required this.screenshot,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderDefault, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: _Img(uri: screenshot.uri),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Img extends StatelessWidget {
  final String uri;
  const _Img({required this.uri});

  @override
  Widget build(BuildContext context) {
    if (uri.startsWith('http')) {
      return Image.network(uri,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) =>
              Container(color: AppColors.bgElevated));
    }
    return Image.file(File(uri),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) =>
            Container(color: AppColors.bgElevated));
  }
}

class _ScreenshotPicker extends StatefulWidget {
  final List<Screenshot> screenshots;
  final ScrollController scrollController;
  final void Function(int) onSelect;

  const _ScreenshotPicker({
    required this.screenshots,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  State<_ScreenshotPicker> createState() => _ScreenshotPickerState();
}

class _ScreenshotPickerState extends State<_ScreenshotPicker> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 12),
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.borderEmphasis,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Add screenshots', style: AppTypography.headingMd),
              const Spacer(),
              if (_selected != null)
                GestureDetector(
                  onTap: () => widget.onSelect(_selected!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Add',
                        style: AppTypography.labelLg
                            .copyWith(color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: widget.screenshots.isEmpty
              ? const Center(
                  child: Text('All screenshots are already in this stack',
                      style: TextStyle(color: AppColors.textMuted)))
              : GridView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: widget.screenshots.length,
                  itemBuilder: (context, i) {
                    final s = widget.screenshots[i];
                    final isSelected = _selected == s.id;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selected = s.id),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.borderSubtle,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _Img(uri: s.uri),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    size: 11, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
