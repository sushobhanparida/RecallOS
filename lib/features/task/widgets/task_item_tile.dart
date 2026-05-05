import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/models/task_model.dart';

class TaskItemTile extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onOpen;

  const TaskItemTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.onOpen,
  });

  bool get isEvent => task.intent == TaskIntent.event;

  @override
  State<TaskItemTile> createState() => _TaskItemTileState();
}

class _TaskItemTileState extends State<TaskItemTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Phase 1 — fill + text swap (0.0 → 0.45)
  late final Animation<double> _fill;
  late final Animation<double> _contentFade;
  late final Animation<double> _overlayFade;

  // Phase 2 — slide + card fade (0.45 → 0.85)
  // _slideFraction: 0 → 1, direction applied at render time via _undoing
  late final Animation<double> _slideFraction;
  late final Animation<double> _cardFade;

  // Phase 3 — height collapse (0.78 → 1.0)
  late final Animation<double> _heightFactor;

  // true while playing the undo (un-complete) animation
  bool _undoing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fill = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _contentFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.32, curve: Curves.easeOut),
      ),
    );

    _overlayFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.12, 0.50, curve: Curves.easeIn),
    );

    _slideFraction = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 0.85, curve: Curves.easeIn),
    );

    _cardFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.60, 0.85, curve: Curves.easeIn),
      ),
    );

    _heightFactor = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.78, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleCheckbox() async {
    // Mark direction before the animation starts so build() reads it correctly.
    setState(() => _undoing = widget.task.isCompleted);
    await _ctrl.forward();
    if (mounted) widget.onToggle();
  }

  // Fill colour: accent (green) for done, tagLink (blue) for restored.
  Color get _fillTarget => _undoing ? AppColors.tagLink : AppColors.accent;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _heightFactor,
      axisAlignment: -1,
      child: AnimatedBuilder(
        animation: _slideFraction,
        builder: (_, child) => FractionalTranslation(
          // Slide right when completing, left when restoring.
          translation:
              Offset(_slideFraction.value * 1.6 * (_undoing ? -1.0 : 1.0), 0),
          child: child!,
        ),
        child: FadeTransition(
          opacity: _cardFade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 1),
            child: AnimatedBuilder(
              animation: _fill,
              builder: (_, child) => Container(
                decoration: BoxDecoration(
                  color: Color.lerp(
                      AppColors.bgSurface, _fillTarget, _fill.value),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color.lerp(
                        AppColors.borderDefault, _fillTarget, _fill.value)!,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.onOpen,
                  onLongPress: () => _showActions(context),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FadeTransition(
                          opacity: _contentFade, child: child!),
                      FadeTransition(
                        opacity: _overlayFade,
                        child: _undoing
                            ? const _RestoredOverlay()
                            : const _DoneOverlay(),
                      ),
                    ],
                  ),
                ),
              ),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final hasReminder = !widget.task.isCompleted &&
        widget.task.notifyOption != NotifyOption.none;
    final isEvent = widget.isEvent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Checkbox (left) — hidden for events
          if (!isEvent)
            _CompletionIcon(
              isCompleted: widget.task.isCompleted,
              onTap: _handleCheckbox,
            )
          else
            // Event calendar icon placeholder same width as checkbox
            const SizedBox(width: 44),

          // Thumbnail
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: _Thumb(uri: widget.task.screenshotUri),
          ),
          const SizedBox(width: 10),

          // Title + optional intent pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: AppTypography.labelLg.copyWith(
                    color: widget.task.isCompleted
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    decoration: widget.task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isEvent && widget.task.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d · h:mm a').format(widget.task.dueDate!),
                    style: AppTypography.monoSm
                        .copyWith(color: AppColors.textMuted),
                  ),
                ] else if (!isEvent && widget.task.intent.label.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  _IntentPill(intent: widget.task.intent),
                ],
              ],
            ),
          ),

          // Time badge (right) — tasks only, when dueDate set
          if (!isEvent && widget.task.dueDate != null && !widget.task.isCompleted) ...[
            const SizedBox(width: 6),
            _TimeBadge(dueDate: widget.task.dueDate!),
          ],

          // Reminder bell for events
          if (isEvent && hasReminder) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.notifications_none_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],

          // Reminder bell for tasks (no due date shown)
          if (!isEvent && widget.task.dueDate == null && hasReminder) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.notifications_none_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
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
            _ActionTile(
              icon: Icons.edit_outlined,
              label: 'Edit',
              iconColor: AppColors.textSecondary,
              textColor: AppColors.textPrimary,
              onTap: () {
                Navigator.pop(context);
                widget.onEdit();
              },
            ),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              iconColor: AppColors.error,
              textColor: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

}

class _TimeBadge extends StatelessWidget {
  final DateTime dueDate;
  const _TimeBadge({required this.dueDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Text(
        DateFormat('h:mm a').format(dueDate),
        style: AppTypography.monoSm.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _IntentPill extends StatelessWidget {
  final TaskIntent intent;
  const _IntentPill({required this.intent});

  @override
  Widget build(BuildContext context) {
    final color = _intentColor(intent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_intentIcon(intent), size: 10, color: color),
          const SizedBox(width: 4),
          Text(intent.label,
              style: AppTypography.labelSm.copyWith(color: color)),
        ],
      ),
    );
  }

  static Color _intentColor(TaskIntent intent) {
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

  static IconData _intentIcon(TaskIntent intent) {
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
}

// ── Overlays ──────────────────────────────────────────────────────────────────

class _DoneOverlay extends StatelessWidget {
  const _DoneOverlay();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(
            'Done',
            style: AppTypography.labelLg.copyWith(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RestoredOverlay extends StatelessWidget {
  const _RestoredOverlay();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.undo_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(
            'Restored',
            style: AppTypography.labelLg.copyWith(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Support widgets ───────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
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
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 14),
            Text(label,
                style: AppTypography.bodyMd.copyWith(color: textColor)),
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
    // 44×44 tap target wrapping a 20×20 visual.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCompleted
                  ? AppColors.accent
                  : AppColors.borderEmphasis,
              width: 1.5,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
              : null,
        ),
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
        child: Icon(Icons.image_outlined,
            color: AppColors.textMuted, size: 16),
      );
    }
    if (uri.startsWith('http')) {
      return Image.network(uri, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined,
              color: AppColors.textMuted, size: 16));
    }
    return Image.file(File(uri), fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined,
            color: AppColors.textMuted, size: 16));
  }
}
