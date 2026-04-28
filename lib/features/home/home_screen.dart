import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/screenshot_model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/empty_state.dart';
import 'home_provider.dart';
import 'widgets/events_ticket_view.dart';
import 'widgets/links_list_view.dart';
import 'widgets/notes_view.dart';
import 'widgets/screenshot_card.dart';
import 'widgets/smart_actions_banner.dart';
import 'widgets/tag_filter_bar.dart';
import '../task/task_provider.dart';
import '../task/widgets/add_to_tasks_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);
    final actions = ref.watch(smartActionsProvider);
    final smartActionsService = ref.read(smartActionsServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              notifier: notifier,
              isImporting: state.isImporting,
              backfillRemaining: state.backfillRemaining,
            ),
            const SizedBox(height: 12),

            // Smart actions banner — UPI / wifi / link / contact QRs etc.
            if (actions.isNotEmpty)
              SmartActionsBanner(
                actions: actions,
                onExecute: (a) => smartActionsService.execute(a, context),
                onOpen: (a) =>
                    context.push('/screenshot/${a.screenshot.id}'),
              ),

            // Screenshots section header — only shown when there's content above
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 4),
                child: Text('Screenshots',
                    style: AppTypography.labelLg
                        .copyWith(color: AppColors.textSecondary)),
              ),

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
              child: _BodyForFilter(
                tagFilter: state.tagFilter,
                screenshots: state.screenshots,
                searchQuery: state.searchQuery,
                onOpen: (s) => context.push('/screenshot/${s.id}'),
                onDelete: (id) => notifier.deleteScreenshot(id),
                onAddToTasks: (s) {
                  final taskNotifier = ref.read(taskProvider.notifier);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.bgElevated,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                      side: BorderSide(
                          color: AppColors.borderDefault, width: 1),
                    ),
                    builder: (_) => AddToTasksSheet(
                      screenshot: s,
                      onCreate: taskNotifier.addTask,
                    ),
                  );
                },
              ),
            ),

            // Compact search at the bottom-left, just above the nav.
            _BottomSearch(
              query: state.searchQuery,
              onChanged: notifier.setSearch,
            ),
          ],
        ),
      ),
    );
  }
}

/// Switches the home grid body based on the active filter. Notes/Links/Events
/// each have a bespoke layout; everything else falls back to the standard
/// 3-col screenshot grid.
class _BodyForFilter extends StatelessWidget {
  final String tagFilter;
  final List<Screenshot> screenshots;
  final String searchQuery;
  final ValueChanged<Screenshot> onOpen;
  final ValueChanged<int> onDelete;
  final ValueChanged<Screenshot> onAddToTasks;

  const _BodyForFilter({
    required this.tagFilter,
    required this.screenshots,
    required this.searchQuery,
    required this.onOpen,
    required this.onDelete,
    required this.onAddToTasks,
  });

  @override
  Widget build(BuildContext context) {
    // Notes shows the fan + Pinterest grid even when there are no
    // note-tagged screenshots (the picker hero card stays visible).
    if (screenshots.isEmpty && tagFilter != 'Notes') {
      return EmptyState(
        icon: Icons.screenshot_monitor_outlined,
        title: searchQuery.isNotEmpty
            ? 'No results'
            : 'No screenshots yet',
        subtitle: searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Import screenshots using the button above',
      );
    }

    switch (tagFilter) {
      case 'Notes':
        return NotesView(
          noteScreenshots: screenshots,
          onOpenScreenshot: onOpen,
        );
      case 'Links':
        return LinksListView(
          screenshots: screenshots,
          onOpen: onOpen,
        );
      case 'Events':
        return EventsTicketView(
          screenshots: screenshots,
          onOpen: onOpen,
        );
      default:
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: screenshots.length,
          itemBuilder: (context, i) {
            final s = screenshots[i];
            return ScreenshotCard(
              screenshot: s,
              onTap: () => onOpen(s),
              onDelete: () => onDelete(s.id!),
              onAddToTasks: () => onAddToTasks(s),
            );
          },
        );
    }
  }
}

class _BottomSearch extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const _BottomSearch({required this.query, required this.onChanged});

  @override
  State<_BottomSearch> createState() => _BottomSearchState();
}

class _BottomSearchState extends State<_BottomSearch> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _BottomSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _ctrl.text) {
      _ctrl.text = widget.query;
      _ctrl.selection =
          TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final expanded = _focus.hasFocus || _ctrl.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: expanded ? 260 : 130,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: expanded
                  ? AppColors.borderEmphasis
                  : AppColors.borderDefault,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search_rounded,
                  size: 16,
                  color: expanded
                      ? AppColors.textSecondary
                      : AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onChanged: widget.onChanged,
                  cursorColor: AppColors.accent,
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: AppTypography.bodySm
                        .copyWith(color: AppColors.textMuted),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_ctrl.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _ctrl.clear();
                    widget.onChanged('');
                    _focus.unfocus();
                    setState(() {});
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.close_rounded,
                        size: 14, color: AppColors.textMuted),
                  ),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final HomeNotifier notifier;
  final bool isImporting;
  final int backfillRemaining;

  const _Header({
    required this.notifier,
    required this.isImporting,
    required this.backfillRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
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
          if (backfillRemaining > 0) ...[
            _BackfillChip(remaining: backfillRemaining),
            const SizedBox(width: 8),
          ],
          _ImportButton(notifier: notifier, isImporting: isImporting),
        ],
      ),
    );
  }
}

class _BackfillChip extends StatelessWidget {
  final int remaining;
  const _BackfillChip({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.2,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 6),
          Text('Indexing $remaining',
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.textMuted)),
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
