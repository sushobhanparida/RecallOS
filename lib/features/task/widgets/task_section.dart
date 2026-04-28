import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/models/task_model.dart';
import 'task_item_tile.dart';

class TaskSection extends StatefulWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<Task> tasks;
  final void Function(Task) onToggle;
  final void Function(int) onDelete;

  const TaskSection({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<TaskSection> createState() => _TaskSectionState();
}

class _TaskSectionState extends State<TaskSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
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
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(
            children: widget.tasks
                .map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: TaskItemTile(
                        task: t,
                        onToggle: () => widget.onToggle(t),
                        onDelete: () => widget.onDelete(t.id!),
                      ),
                    ))
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
