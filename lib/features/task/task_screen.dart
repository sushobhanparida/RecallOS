import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/models/task_model.dart';
import '../../shared/widgets/app_fab.dart';
import '../../shared/widgets/empty_state.dart';
import 'task_provider.dart';
import 'widgets/task_item_tile.dart';
import 'widgets/task_section.dart';
import 'widgets/add_to_tasks_sheet.dart';

class TaskScreen extends ConsumerWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskProvider);
    final notifier = ref.read(taskProvider.notifier);

    final hasAny = state.activeTasks.isNotEmpty || state.completedTasks.isNotEmpty;

    void showSheet({Task? existing, DateTime? defaultDate}) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.bgElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          side: BorderSide(color: AppColors.borderDefault, width: 1),
        ),
        builder: (_) => AddToTasksSheet(
          screenshot: null,
          existingTask: existing,
          initialDueDate: defaultDate,
          onCreate: notifier.addTask,
          onUpdate: notifier.updateTask,
        ),
      );
    }

    void openDetail(Task t) => context.push('/tasks/${t.id}');

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      floatingActionButton: AppFab(onPressed: () => showSheet()),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: 16),
            Expanded(
              child: !hasAny
                  ? const EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: "You're all caught up!",
                      subtitle: 'Tasks from screenshots appear here',
                    )
                  : Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.only(bottom: 100),
                          children: [
                            if (state.eventTasks.isNotEmpty)
                              TaskSection(
                                title: 'Events',
                                color: AppColors.tagEvent,
                                icon: Icons.calendar_today_outlined,
                                tasks: state.eventTasks,
                                onToggle: notifier.toggleComplete,
                                onDelete: notifier.deleteTask,
                                onEdit: (t) => showSheet(existing: t),
                                onOpen: openDetail,
                              ),
                            if (state.todayTasks.isNotEmpty)
                              TaskSection(
                                title: 'Today',
                                color: AppColors.accent,
                                icon: Icons.wb_sunny_outlined,
                                tasks: state.todayTasks,
                                onToggle: notifier.toggleComplete,
                                onDelete: notifier.deleteTask,
                                onEdit: (t) => showSheet(existing: t),
                                onOpen: openDetail,
                                onAddTap: () {
                                  final today = DateTime.now();
                                  showSheet(
                                    defaultDate: DateTime(
                                        today.year, today.month, today.day, 9),
                                  );
                                },
                              ),
                            if (state.tomorrowTasks.isNotEmpty)
                              TaskSection(
                                title: 'Tomorrow',
                                color: AppColors.textSecondary,
                                icon: Icons.today_outlined,
                                tasks: state.tomorrowTasks,
                                onToggle: notifier.toggleComplete,
                                onDelete: notifier.deleteTask,
                                onEdit: (t) => showSheet(existing: t),
                                onOpen: openDetail,
                                onAddTap: () {
                                  final tomorrow = DateTime.now()
                                      .add(const Duration(days: 1));
                                  showSheet(
                                    defaultDate: DateTime(tomorrow.year,
                                        tomorrow.month, tomorrow.day, 9),
                                  );
                                },
                              ),
                            if (state.upcomingTasks.isNotEmpty)
                              TaskSection(
                                title: 'Upcoming',
                                color: AppColors.textMuted,
                                icon: Icons.date_range_outlined,
                                tasks: state.upcomingTasks,
                                onToggle: notifier.toggleComplete,
                                onDelete: notifier.deleteTask,
                                onEdit: (t) => showSheet(existing: t),
                                onOpen: openDetail,
                              ),
                            if (state.somedayTasks.isNotEmpty)
                              TaskSection(
                                title: 'Someday',
                                color: AppColors.textMuted,
                                icon: Icons.hourglass_empty_rounded,
                                tasks: state.somedayTasks,
                                onToggle: notifier.toggleComplete,
                                onDelete: notifier.deleteTask,
                                onEdit: (t) => showSheet(existing: t),
                                onOpen: openDetail,
                              ),
                            if (state.completedTasks.isNotEmpty)
                              _CompletedSection(
                                tasks: state.completedTasks,
                                onToggle: notifier.toggleComplete,
                                onDelete: notifier.deleteTask,
                                onEdit: (t) => showSheet(existing: t),
                                onOpen: openDetail,
                              ),
                          ],
                        ),
                        // Top fade
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 16,
                          child: IgnorePointer(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.bgBase,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('EEEE').format(now), style: AppTypography.displayMd),
          const SizedBox(height: 2),
          Text(
            DateFormat('MMMM d, yyyy').format(now),
            style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CompletedSection extends StatefulWidget {
  final List<Task> tasks;
  final void Function(Task) onToggle;
  final void Function(int) onDelete;
  final void Function(Task) onEdit;
  final void Function(Task) onOpen;

  const _CompletedSection({
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onOpen,
  });

  @override
  State<_CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends State<_CompletedSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _size;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _size = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.textMuted, size: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed',
                  style: AppTypography.headingSm
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: AppColors.borderDefault, width: 1),
                  ),
                  child: Text(
                    '${widget.tasks.length}',
                    style: AppTypography.monoSm
                        .copyWith(color: AppColors.textMuted),
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => Icon(
                    _ctrl.value > 0.5
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _size,
          axisAlignment: -1.0,
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              children: widget.tasks
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: TaskItemTile(
                          task: t,
                          onToggle: () => widget.onToggle(t),
                          onDelete: () => widget.onDelete(t.id!),
                          onEdit: () => widget.onEdit(t),
                          onOpen: () => widget.onOpen(t),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
