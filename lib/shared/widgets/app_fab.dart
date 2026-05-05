import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class AppFab extends StatefulWidget {
  final VoidCallback onPressed;

  const AppFab({super.key, required this.onPressed});

  @override
  State<AppFab> createState() => _AppFabState();
}

class _AppFabState extends State<AppFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          color: AppColors.accent,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            onTap: widget.onPressed,
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withValues(alpha: 0.18),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
