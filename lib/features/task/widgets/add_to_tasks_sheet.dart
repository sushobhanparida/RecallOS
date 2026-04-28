import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/screenshot_model.dart';
import '../../../core/models/task_model.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../task_prefill.dart';

enum _FormVariant { generic, event, simple }

class AddToTasksSheet extends StatefulWidget {
  final Screenshot? screenshot;
  final void Function(Task) onCreate;

  const AddToTasksSheet({
    super.key,
    this.screenshot,
    required this.onCreate,
  });

  @override
  State<AddToTasksSheet> createState() => _AddToTasksSheetState();
}

class _AddToTasksSheetState extends State<AddToTasksSheet> {
  late final TextEditingController _titleCtrl;
  late final _FormVariant _variant;
  late final TaskIntent _intent;
  late final String? _contextLabel; // url or amount to display

  DateTime? _dueDate;
  NotifyOption _notifyOption = NotifyOption.none;

  @override
  void initState() {
    super.initState();

    if (widget.screenshot == null) {
      _variant = _FormVariant.generic;
      _intent = TaskIntent.task;
      _contextLabel = null;
      _titleCtrl = TextEditingController();
    } else {
      final prefill = TaskPrefill.fromScreenshot(widget.screenshot!);
      _intent = prefill.intent;
      _dueDate = prefill.dueDate;

      if (widget.screenshot!.tag == ScreenshotTag.event) {
        _variant = _FormVariant.event;
        _contextLabel = null;
      } else {
        _variant = _FormVariant.simple;
        _contextLabel = prefill.url ?? prefill.amount;
      }

      _titleCtrl = TextEditingController(text: prefill.title);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onCreate(Task(
      screenshotId: widget.screenshot?.id ?? 0,
      screenshotUri: widget.screenshot?.uri ?? '',
      title: title,
      intent: _intent,
      dueDate: _dueDate,
      notifyOption: _notifyOption,
      createdAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.borderEmphasis,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Text(
            _variant == _FormVariant.generic ? 'New Task' : 'Add to Tasks',
            style:
                AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),

          // Title field
          _FieldLabel('Task'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            autofocus: _titleCtrl.text.isEmpty,
            style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
            decoration: _inputDecoration('What needs to be done?'),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),

          // Variant-specific fields
          if (_variant == _FormVariant.event) ..._eventFields(),
          if (_variant == _FormVariant.simple) ..._simpleFields(),
          if (_variant == _FormVariant.generic) ..._genericFields(),

          const SizedBox(height: 20),

          // Create button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Create Task',
                    style: AppTypography.labelLg
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _eventFields() {
    return [
      // Date + time picker
      _FieldLabel('Date & Time'),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: _pickDateTime,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDefault, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 15, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Text(
                _dueDate != null
                    ? DateFormat('MMM d, yyyy · HH:mm').format(_dueDate!)
                    : 'Pick a date and time',
                style: AppTypography.bodyMd.copyWith(
                  color: _dueDate != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),

      // Notify option
      _FieldLabel('Notify'),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDefault, width: 1),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<NotifyOption>(
            value: _notifyOption,
            isExpanded: true,
            dropdownColor: AppColors.bgElevated,
            style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted, size: 18),
            items: NotifyOption.values
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o.label),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _notifyOption = v);
            },
          ),
        ),
      ),
    ];
  }

  List<Widget> _simpleFields() {
    return [
      // Intent label chip (read-only)
      if (_intent.label.isNotEmpty) ...[
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _intentColor(_intent).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: _intentColor(_intent).withValues(alpha: 0.3),
                    width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_intentIcon(_intent),
                      size: 11, color: _intentColor(_intent)),
                  const SizedBox(width: 5),
                  Text(
                    _intent.label,
                    style: AppTypography.labelSm
                        .copyWith(color: _intentColor(_intent)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],

      // Context label (url or amount)
      if (_contextLabel != null && _contextLabel.isNotEmpty) ...[
        _FieldLabel('Context'),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDefault, width: 1),
          ),
          child: Text(
            _contextLabel,
            style:
                AppTypography.monoMd.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 14),
      ],

      // Optional due date
      _FieldLabel('Due Date (optional)'),
      const SizedBox(height: 6),
      _DueDateButton(
        dueDate: _dueDate,
        onTap: _pickDateTime,
      ),
    ];
  }

  List<Widget> _genericFields() {
    return [
      _FieldLabel('Due Date (optional)'),
      const SizedBox(height: 6),
      _DueDateButton(
        dueDate: _dueDate,
        onTap: _pickDateTime,
      ),
    ];
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => _darkPickerTheme(ctx, child),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _dueDate != null
          ? TimeOfDay(hour: _dueDate!.hour, minute: _dueDate!.minute)
          : TimeOfDay.now(),
      builder: (ctx, child) => _darkPickerTheme(ctx, child),
    );
    if (!mounted) return;

    setState(() {
      _dueDate = time != null
          ? DateTime(date.year, date.month, date.day, time.hour, time.minute)
          : DateTime(date.year, date.month, date.day);
    });
  }

  Widget _darkPickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          onPrimary: Colors.white,
          surface: AppColors.bgElevated,
          onSurface: AppColors.textPrimary,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.bgElevated,
        ),
      ),
      child: child!,
    );
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.bgSurface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDefault, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderDefault, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 1),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelMd.copyWith(color: AppColors.textMuted),
    );
  }
}

class _DueDateButton extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onTap;

  const _DueDateButton({required this.dueDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDefault, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 15, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Text(
              dueDate != null
                  ? DateFormat('MMM d, yyyy · HH:mm').format(dueDate!)
                  : 'None',
              style: AppTypography.bodyMd.copyWith(
                color: dueDate != null
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
