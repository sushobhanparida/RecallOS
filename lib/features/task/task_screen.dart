import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/empty_state.dart';
import 'task_provider.dart';
import 'widgets/task_section.dart';
import 'widgets/add_to_tasks_sheet.dart';

class TaskScreen extends ConsumerWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskProvider);
    final notifier = ref.read(taskProvider.notifier);
    final hasAny = state.tasks.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            Expanded(
              child: hasAny
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        if (state.eventTasks.isNotEmpty)
                          TaskSection(
                            title: 'Events',
                            color: AppColors.tagEvent,
                            icon: Icons.calendar_today_rounded,
                            tasks: state.eventTasks,
                            onToggle: notifier.toggleComplete,
                            onDelete: notifier.deleteTask,
                          ),
                        if (state.simpleTasks.isNotEmpty)
                          TaskSection(
                            title: 'Tasks',
                            color: AppColors.accent,
                            icon: Icons.task_alt_rounded,
                            tasks: state.simpleTasks,
                            onToggle: notifier.toggleComplete,
                            onDelete: notifier.deleteTask,
                          ),
                      ],
                    )
                  : const EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: "You're all caught up!",
                      subtitle:
                          'Tasks from screenshots appear here',
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        onPressed: () => _showCreateSheet(context, ref),
        child: const Icon(Icons.add_rounded, size: 22),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(taskProvider.notifier);
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
        onCreate: notifier.addTask,
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
          Text(
            DateFormat('EEEE').format(now),
            style: AppTypography.displayMd,
          ),
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
