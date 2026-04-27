import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/models/todo_model.dart';
import '../../shared/widgets/empty_state.dart';
import 'todo_provider.dart';
import 'widgets/todo_section.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todoProvider);
    final notifier = ref.read(todoProvider.notifier);
    final hasAny = state.todos.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            Expanded(
              child: hasAny
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        if (state.events.isNotEmpty)
                          TodoSection(
                            title: 'Events',
                            color: AppColors.sectionEvent,
                            icon: Icons.calendar_today_rounded,
                            todos: state.events,
                            onToggle: notifier.toggleComplete,
                            onDelete: notifier.deleteTodo,
                          ),
                        if (state.morning.isNotEmpty)
                          TodoSection(
                            title: 'Morning',
                            color: AppColors.sectionMorning,
                            icon: Icons.wb_sunny_outlined,
                            todos: state.morning,
                            onToggle: notifier.toggleComplete,
                            onDelete: notifier.deleteTodo,
                          ),
                        if (state.afternoon.isNotEmpty)
                          TodoSection(
                            title: 'Afternoon',
                            color: AppColors.sectionAfternoon,
                            icon: Icons.wb_twilight_outlined,
                            todos: state.afternoon,
                            onToggle: notifier.toggleComplete,
                            onDelete: notifier.deleteTodo,
                          ),
                        if (state.anytime.isNotEmpty)
                          TodoSection(
                            title: 'Anytime',
                            color: AppColors.sectionAnytime,
                            icon: Icons.all_inclusive_rounded,
                            todos: state.anytime,
                            onToggle: notifier.toggleComplete,
                            onDelete: notifier.deleteTodo,
                          ),
                      ],
                    )
                  : const EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: "You're all caught up!",
                      subtitle:
                          'Tasks extracted from screenshots appear here',
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add_rounded, size: 22),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppColors.borderDefault, width: 1),
      ),
      builder: (ctx) => _CreateTodoSheet(
        onCreate: (todo) => ref.read(todoProvider.notifier).addTodo(todo),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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

class _CreateTodoSheet extends StatefulWidget {
  final void Function(Todo) onCreate;

  const _CreateTodoSheet({required this.onCreate});

  @override
  State<_CreateTodoSheet> createState() => _CreateTodoSheetState();
}

class _CreateTodoSheetState extends State<_CreateTodoSheet> {
  final _titleCtrl = TextEditingController();
  TodoCategory _category = TodoCategory.anytime;
  TodoDuration _duration = TodoDuration.fifteenMin;
  bool _isEvent = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.borderEmphasis,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('New Task', style: AppTypography.headingMd),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: AppTypography.bodyLg.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Task title...',
              hintStyle:
                  AppTypography.bodyLg.copyWith(color: AppColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.borderDefault, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.borderDefault, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.borderFocus, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.bgSurface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            cursorColor: AppColors.accent,
          ),
          const SizedBox(height: 12),
          // Category row
          _FieldRow(
            label: 'Category',
            child: _SegmentedPicker<TodoCategory>(
              values: TodoCategory.values,
              selected: _category,
              label: (c) => c.label,
              onChanged: (c) => setState(() => _category = c),
            ),
          ),
          const SizedBox(height: 10),
          _FieldRow(
            label: 'Duration',
            child: _SegmentedPicker<TodoDuration>(
              values: TodoDuration.values,
              selected: _duration,
              label: (d) => d.label,
              onChanged: (d) => setState(() => _duration = d),
            ),
          ),
          const SizedBox(height: 10),
          _FieldRow(
            label: 'Type',
            child: GestureDetector(
              onTap: () => setState(() => _isEvent = !_isEvent),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isEvent
                      ? AppColors.successMuted
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isEvent
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.borderDefault,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isEvent
                          ? Icons.calendar_today_rounded
                          : Icons.task_alt_rounded,
                      size: 13,
                      color: _isEvent
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isEvent ? 'Event' : 'Task',
                      style: AppTypography.labelMd.copyWith(
                        color: _isEvent
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.borderDefault, width: 1),
                    ),
                    child: Center(
                      child: Text('Cancel',
                          style: AppTypography.labelLg
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('Add Task',
                          style: AppTypography.labelLg
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onCreate(Todo(
      screenshotId: 0,
      screenshotUri: '',
      title: title,
      category: _category,
      duration: _duration,
      isEvent: _isEvent,
      createdAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style:
                  AppTypography.labelMd.copyWith(color: AppColors.textMuted)),
        ),
        child,
      ],
    );
  }
}

class _SegmentedPicker<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  const _SegmentedPicker({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values.map((v) {
          final isSelected = v == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => onChanged(v),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentMuted
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : AppColors.borderDefault,
                    width: 1,
                  ),
                ),
                child: Text(
                  label(v),
                  style: AppTypography.labelMd.copyWith(
                    color: isSelected
                        ? AppColors.accentText
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
