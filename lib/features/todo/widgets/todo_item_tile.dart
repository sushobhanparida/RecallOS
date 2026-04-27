import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/models/todo_model.dart';

class TodoItemTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoItemTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDefault, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.borderSubtle, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _Thumb(uri: todo.screenshotUri),
                ),
                const SizedBox(width: 12),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: AppTypography.labelLg.copyWith(
                          color: todo.isCompleted
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (todo.isEvent)
                            const Icon(Icons.calendar_today_outlined,
                                size: 11, color: AppColors.sectionEvent)
                          else
                            Icon(Icons.access_time_rounded,
                                size: 11,
                                color: _categoryColor(todo.category)),
                          const SizedBox(width: 4),
                          Text(
                            _meta(),
                            style: AppTypography.monoSm,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right actions
                const SizedBox(width: 8),
                _CompletionIcon(isCompleted: todo.isCompleted, onTap: onToggle),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showMenu(context),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.more_horiz_rounded,
                        size: 16, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _meta() {
    final parts = <String>[];
    if (todo.dueDate != null) {
      final dt = todo.dueDate!;
      parts.add(
          '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}');
    }
    parts.add(todo.duration.label);
    return parts.join(' · ');
  }

  Color _categoryColor(TodoCategory cat) {
    switch (cat) {
      case TodoCategory.morning:
        return AppColors.sectionMorning;
      case TodoCategory.afternoon:
        return AppColors.sectionAfternoon;
      case TodoCategory.anytime:
        return AppColors.sectionAnytime;
      case TodoCategory.event:
        return AppColors.sectionEvent;
    }
  }

  void _showMenu(BuildContext context) {
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
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 18),
              title: Text('Delete',
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CompletionIcon extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onTap;

  const _CompletionIcon({required this.isCompleted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCompleted ? AppColors.accent : AppColors.borderEmphasis,
            width: 1.5,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
            : null,
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String uri;
  const _Thumb({required this.uri});

  @override
  Widget build(BuildContext context) {
    if (uri.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 16),
      );
    }
    if (uri.startsWith('http')) {
      return Image.network(uri, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
              Icons.image_outlined,
              color: AppColors.textMuted,
              size: 16));
    }
    return Image.file(File(uri), fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
            Icons.image_outlined,
            color: AppColors.textMuted,
            size: 16));
  }
}
