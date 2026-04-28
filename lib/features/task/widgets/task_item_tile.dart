import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/models/task_model.dart';

class TaskItemTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskItemTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 1),
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
                  child: _Thumb(uri: task.screenshotUri),
                ),
                const SizedBox(width: 12),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: AppTypography.labelLg.copyWith(
                          color: task.isCompleted
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          decoration: task.isCompleted
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
                          Icon(
                            _intentIcon(task.intent),
                            size: 11,
                            color: _intentColor(task.intent),
                          ),
                          const SizedBox(width: 4),
                          if (task.dueDate != null)
                            Text(
                              DateFormat('MMM d · HH:mm').format(task.dueDate!),
                              style: AppTypography.monoSm,
                            ),
                          if (task.dueDate != null &&
                              task.intent.label.isNotEmpty)
                            Text(' · ',
                                style: AppTypography.monoSm
                                    .copyWith(color: AppColors.textMuted)),
                          if (task.intent.label.isNotEmpty)
                            Text(
                              task.intent.label,
                              style: AppTypography.monoSm.copyWith(
                                  color: _intentColor(task.intent)),
                            ),
                          if (task.dueDate == null &&
                              task.intent.label.isEmpty)
                            Text(
                              'Task',
                              style: AppTypography.monoSm
                                  .copyWith(color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right actions
                const SizedBox(width: 8),
                _CompletionIcon(
                    isCompleted: task.isCompleted, onTap: onToggle),
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

  IconData _intentIcon(TaskIntent intent) {
    switch (intent) {
      case TaskIntent.event:
        return Icons.calendar_today_outlined;
      case TaskIntent.visitLater:
        return Icons.link_rounded;
      case TaskIntent.payLater:
        return Icons.payments_outlined;
      case TaskIntent.readLater:
        return Icons.menu_book_outlined;
      case TaskIntent.buyLater:
        return Icons.shopping_bag_outlined;
      case TaskIntent.task:
        return Icons.task_alt_rounded;
    }
  }

  Color _intentColor(TaskIntent intent) {
    switch (intent) {
      case TaskIntent.event:
        return AppColors.tagEvent;
      case TaskIntent.visitLater:
        return AppColors.tagLink;
      case TaskIntent.payLater:
        return AppColors.tagShopping;
      case TaskIntent.readLater:
        return AppColors.tagNote;
      case TaskIntent.buyLater:
        return AppColors.tagShopping;
      case TaskIntent.task:
        return AppColors.textMuted;
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
