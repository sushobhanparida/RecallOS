import 'dart:async';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

/// Terminal-style typewriter that cycles through [lines], typing each one
/// character by character then deleting before moving to the next.
class TypewriterText extends StatefulWidget {
  final List<String> lines;

  /// Base text style. Defaults to JetBrains Mono 13px textSecondary.
  final TextStyle? style;

  /// Colour of the blinking block cursor. Defaults to [AppColors.accentText].
  final Color cursorColor;

  final TextAlign textAlign;

  const TypewriterText({
    super.key,
    required this.lines,
    this.style,
    this.cursorColor = AppColors.accentText,
    this.textAlign = TextAlign.center,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  static const _typeDelay = Duration(milliseconds: 52);
  static const _deleteDelay = Duration(milliseconds: 26);
  static const _pauseAfterType = Duration(milliseconds: 5000);
  static const _pauseBeforeNext = Duration(milliseconds: 320);
  static const _cursorPeriod = Duration(milliseconds: 530);

  int _lineIndex = 0;
  int _charCount = 0;
  bool _cursorOn = true;
  Timer? _typeTimer;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(_cursorPeriod, (_) {
      if (mounted) setState(() => _cursorOn = !_cursorOn);
    });
    if (widget.lines.isNotEmpty) _scheduleType();
  }

  @override
  void didUpdateWidget(TypewriterText old) {
    super.didUpdateWidget(old);
    if (!listEquals(widget.lines, old.lines) && widget.lines.isNotEmpty) {
      _typeTimer?.cancel();
      setState(() {
        _lineIndex = 0;
        _charCount = 0;
      });
      _scheduleType();
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _scheduleType() {
    _typeTimer = Timer.periodic(_typeDelay, (_) {
      if (!mounted) return;
      final full = _currentLine;
      if (_charCount < full.length) {
        setState(() => _charCount++);
      } else {
        _typeTimer?.cancel();
        _typeTimer = Timer(_pauseAfterType, _scheduleDelete);
      }
    });
  }

  void _scheduleDelete() {
    _typeTimer = Timer.periodic(_deleteDelay, (_) {
      if (!mounted) return;
      if (_charCount > 0) {
        setState(() => _charCount--);
      } else {
        _typeTimer?.cancel();
        setState(() => _lineIndex = (_lineIndex + 1) % widget.lines.length);
        _typeTimer = Timer(_pauseBeforeNext, _scheduleType);
      }
    });
  }

  String get _currentLine {
    if (widget.lines.isEmpty) return '';
    return widget.lines[_lineIndex % widget.lines.length];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return const SizedBox.shrink();
    final line = _currentLine;
    final safe = _charCount.clamp(0, line.length);
    final text = line.substring(0, safe);
    final base = widget.style ?? AppTypography.monoMd.copyWith(fontSize: 13);

    return Text.rich(
      TextSpan(children: [
        TextSpan(text: text, style: base),
        TextSpan(
          text: _cursorOn ? '█' : ' ',
          style: base.copyWith(color: widget.cursorColor),
        ),
      ]),
      textAlign: widget.textAlign,
    );
  }
}
