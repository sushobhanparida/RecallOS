import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class LinearSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const LinearSearchBar({
    super.key,
    this.hint = 'Search...',
    required this.onChanged,
    this.controller,
  });

  @override
  State<LinearSearchBar> createState() => _LinearSearchBarState();
}

class _LinearSearchBarState extends State<LinearSearchBar> {
  late final TextEditingController _ctrl;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? TextEditingController();
    _ctrl.addListener(() {
      setState(() => _hasText = _ctrl.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onChanged,
              style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.hint,
                hintStyle: AppTypography.bodyMd
                    .copyWith(color: AppColors.textMuted),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              cursorColor: AppColors.accent,
              cursorWidth: 1.5,
            ),
          ),
          if (_hasText)
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                widget.onChanged('');
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 14),
              ),
            ),
          if (!_hasText) const SizedBox(width: 10),
        ],
      ),
    );
  }
}
