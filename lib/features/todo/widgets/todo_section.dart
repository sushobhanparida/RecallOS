import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/models/todo_model.dart';
import 'todo_item_tile.dart';

class TodoSection extends StatefulWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<Todo> todos;
  final void Function(Todo) onToggle;
  final void Function(int) onDelete;

  const TodoSection({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.todos,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<TodoSection> createState() => _TodoSectionState();
}

class _TodoSectionState extends State<TodoSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    '${widget.todos.length}',
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
        // Items
        AnimatedCrossFade(
          firstChild: Column(
            children: widget.todos
                .map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: TodoItemTile(
                        todo: t,
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
